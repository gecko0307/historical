/*
Copyright (c) 2014 Timur Gafarov 

Boost Software License - Version 1.0 - August 17th, 2003

Permission is hereby granted, free of charge, to any person or organization
obtaining a copy of the software and accompanying documentation covered by
this license (the "Software") to use, reproduce, display, distribute,
execute, and transmit the Software, and to prepare derivative works of the
Software, and to permit third-parties to whom the Software is furnished to
do so, all subject to the following:

The copyright notices in the Software and this entire statement, including
the above license grant, this restriction and the following disclaimer,
must be included in all copies of the Software, in whole or in part, and
all derivative works of the Software, unless such copies or derivative
works are solely in the form of machine-executable object code generated by
a source language processor.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
*/

module gscript.gs;

import std.stdio;
import std.math;
import std.path;
import std.conv;
import std.utf;
import std.functional;
import std.algorithm;
import std.array;
import std.ascii;

import gscript.parser;
import gscript.statement;
import gscript.vm;
import gscript.dynamic;
import gscript.program;

/*
 * Script object represents a single GScript program,
 * with AST and IR code.
 * Once created, Script can be used and reused.
 * You can execute any local function from it
 * via GScript.executeFunction.
 */
class Script
{
    Module modul;
    alias modul this;

    string[] code;

    VirtualMachine vm;
}

/*
 * GScript is a factory object that compiles and links Scripts,
 * and executes functions from them.
 */
class GScript
{
   protected:
    Program prog;

   public:
    this()
    {
        prog = new Program();
        prog.addHostFunction("length", 1, &host_length);
        prog.addHostFunction("array", -1, &host_array);
        prog.addHostFunction("writeln", -1, &host_writeln);
        prog.addHostFunction("sqrt", 1, &host_sqrt);
        prog.addHostFunction("pow", 2, &host_pow);
        prog.addHostFunction("float", 1, &host_float);
        prog.addHostFunction("sin", 1, &host_sin);
        prog.addHostFunction("cos", 1, &host_cos);
        prog.addHostFunction("typestr", 1, &host_typestr);
        prog.addHostFunction("chcode", 1, &host_chcode);
        prog.addHostFunction("format", -1, &host_format);
    }

    void addImportDir(string dir)
    {
        prog.addImportDir(dir);
    }

    void expose(string name, int numArgs, Dynamic delegate(VirtualMachine, Dynamic[]) func)
    {
        prog.addHostFunction(name, numArgs, func);
    }

    void expose(string name, int numArgs, Dynamic function(VirtualMachine, Dynamic[]) func)
    {
        prog.addHostFunction(name, numArgs, toDelegate(func));
    }

    Script loadScript(string text, string filename)
    {
        Script script = new Script();
        Parser parser = new Parser(prog, text, filename.extension, filename);
        script.modul = parser.moduleTree;
        script.code = generateCode(script);
        return script;
    }

    void executeFunction(Script script, string name, Dynamic[] args = [])
    {
        if (script.code.length > 0)
        {
            if (script.vm is null)
                script.vm = new VirtualMachine(script.code, prog);

            if (script.modul.hasLocalFunction(name))
                script.vm.runFunction(script.modul.getLocalFunction(name), args);
            else
                writeln("No function \"" ~ name ~ "\" found");
        }
    }

   protected:
    Dynamic host_length(VirtualMachine vm, Dynamic[] args)
    {
        assert(args.length == 1);
        if (args[0].type == Type.Array)
            return Dynamic(args[0].asArray.length);
        else if (args[0].type == Type.String)
            return Dynamic(std.algorithm.count(args[0].asString));
        else
            return Dynamic(1);
    }

    Dynamic host_array(VirtualMachine vm, Dynamic[] args)
    {
        Dynamic[] arr;
        if (args.length == 0)
        {
            arr = [];
        }
        else if (args.length == 1)
        {
            if (args[0].type == Type.Float)
                arr = new Dynamic[cast(uint)(args[0].asFloat)];
            else if (args[0].type == Type.Array)
                return args[0];
            else if (args[0].type == Type.String)
                arr = [args[0]];
            else
                arr = [];
        }
        else
        {
            foreach(v; args)
                arr ~= v;
        }
        return Dynamic(arr);
    }

    Dynamic host_writeln(VirtualMachine vm, Dynamic[] args)
    {
        if (args.length > 1)
            writeln(args);
        else if (args.length > 0)
            writeln(args[0]);
        else
            writeln();
        return Dynamic(0.0f);
    }

    Dynamic host_typestr(VirtualMachine vm, Dynamic[] args)
    {
        // TODO: traceback instead of assert
        assert(args.length == 1);
        return Dynamic(args[0].type.to!string);
    }

    Dynamic host_sqrt(VirtualMachine vm, Dynamic[] args)
    {
        // TODO: traceback instead of assert
        assert(args.length == 1);

        if (args[0].type != Type.Float)
            vm.traceback("Wrong argument type for \"sqrt\"");

        float res = sqrt(args[0].asFloat);
        return Dynamic(res);
    }

    Dynamic host_pow(VirtualMachine vm, Dynamic[] args)
    {
        // TODO: traceback instead of assert
        assert(args.length == 2);

        if (args[0].type != Type.Float ||
            args[1].type != Type.Float)
            vm.traceback("Wrong argument type for \"pow\"");

        float res = args[0].asFloat ^^ args[1].asFloat;
        return Dynamic(res);
    }

    Dynamic host_float(VirtualMachine vm, Dynamic[] args)
    {
        // TODO: traceback instead of assert
        assert(args.length == 1);

        if (args[0].type != Type.String)
            vm.traceback("Wrong argument type for \"float\"");
        return Dynamic(args[0].asString.to!float);
    }

    Dynamic host_sin(VirtualMachine vm, Dynamic[] args)
    {
        // TODO: traceback instead of assert
        assert(args.length == 1);

        if (args[0].type != Type.Float)
            vm.traceback("Wrong argument type for \"sin\"");
        return Dynamic(sin(args[0].asFloat));
    }

    Dynamic host_cos(VirtualMachine vm, Dynamic[] args)
    {
        // TODO: traceback instead of assert
        assert(args.length == 1);

        if (args[0].type != Type.Float)
            vm.traceback("Wrong argument type for \"sin\"");
        return Dynamic(cos(args[0].asFloat));
    }

    Dynamic host_chcode(VirtualMachine vm, Dynamic[] args)
    {
        // TODO: traceback instead of assert
        assert(args.length == 1);

        if (args[0].type != Type.String)
            vm.traceback("Wrong argument type for \"chcode\"");

        return Dynamic(cast(uint)decodeFront(args[0].asString));
    }

    Dynamic host_format(VirtualMachine vm, Dynamic[] args)
    {
        // TODO: traceback instead of assert
        assert(args.length > 0);

        if (args[0].type != Type.String)
            vm.traceback("Wrong argument type for \"format\"");

        string str = args[0].asString;

        auto appOutput = appender!string();
        auto appIndex = appender!string();
        bool expectIndex = false;

        foreach(i, c; str)
        {
            if (c == '%')
            {
                if (expectIndex)
                {
                    expectIndex = false;
                    appOutput.put(c);
                }
                else
                {
                    expectIndex = true;
                    appIndex = appIndex.init;
                }
            }
            else if (isDigit(c))
            {
                if (expectIndex)
                    appIndex.put(c);
                else
                    appOutput.put(c);
            }
            else
            {
                if (expectIndex)
                {
                    expectIndex = false;
                    string data = appIndex.data;
                    // TODO: check if data is number
                    size_t index = to!size_t(data);
                    // TODO: check if index is valid
                    appOutput.put(args[index+1].toString);
                }

                appOutput.put(c);
            }
        }

        if (expectIndex)
        {
            expectIndex = false;
            string data = appIndex.data;
            // TODO: check if data is number
            size_t index = to!size_t(data);
            // TODO: check if index is valid
            appOutput.put(args[index+1].toString);
        }

        return Dynamic(appOutput.data);
    }

    string[] generateCode(Script s)
    {
        string[] res;
        res ~= "pass";
        res ~= "end";
        foreach(m; s.modul.imports)
            res ~= prog.modules[m.name].postfixCode();
        res ~= s.modul.postfixCode();
        return res;
    }
}
