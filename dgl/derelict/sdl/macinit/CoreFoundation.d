/*

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
module derelict.sdl.macinit.CoreFoundation;

version(DigitalMars) version(OSX) version = darwin;

version (darwin):

import derelict.util.compat;
import derelict.util.loader;

package:

// CFBase types
private struct __CFAllocator;
alias __CFAllocator* CFAllocatorRef;

alias int CFIndex;
alias /*const*/ void* CFTypeRef;



// CFBundle types
private alias void* __CFBundle;
alias __CFBundle *CFBundleRef;



// CFDictionary types;
private alias void* __CFDictionary;
alias __CFDictionary* CFDictionaryRef;



// CFURL types;
private alias void* __CFURL;
alias __CFURL* CFURLRef;




extern (C)
{
    mixin(gsharedString!() ~ "
    //  CFBase bindings from the CoreFoundation framework
    void function(CFTypeRef cf) CFRelease;



    //   CFBundle bindings from the CoreFoundation framework
    CFDictionaryRef function(CFBundleRef bundle) CFBundleGetInfoDictionary;
    CFBundleRef function() CFBundleGetMainBundle;
    CFURLRef function(CFBundleRef bundle) CFBundleCopyBundleURL;



    //   CFURL bindings from the CoreFoundation framework
    CFURLRef function(CFAllocatorRef allocator, CFURLRef url) CFURLCreateCopyDeletingLastPathComponent;
    bool function(CFURLRef url, bool resolveAgainstBase, ubyte* buffer, CFIndex maxBufLen) CFURLGetFileSystemRepresentation;");
}

void load (void delegate(void**, string, bool doThrow = true) bindFunc)
{
    bindFunc(cast(void**)&CFRelease, "CFRelease");
    bindFunc(cast(void**)&CFBundleGetInfoDictionary, "CFBundleGetInfoDictionary");
    bindFunc(cast(void**)&CFBundleGetMainBundle, "CFBundleGetMainBundle");
    bindFunc(cast(void**)&CFBundleCopyBundleURL, "CFBundleCopyBundleURL");
    bindFunc(cast(void**)&CFURLCreateCopyDeletingLastPathComponent, "CFURLCreateCopyDeletingLastPathComponent");
    bindFunc(cast(void**)&CFURLGetFileSystemRepresentation, "CFURLGetFileSystemRepresentation");
}