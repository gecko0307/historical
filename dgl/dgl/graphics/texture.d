/*
Copyright (c) 2013-2016 Timur Gafarov

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

module dgl.graphics.texture;

import std.conv;

import derelict.opengl.gl;
import derelict.opengl.glu;

import dlib.core.memory;
import dlib.image.image;
import dlib.math.vector;

import dgl.core.interfaces;

class Texture: Modifier
{
    GLuint tex;
    GLenum format;
    GLenum type;
    int width;
    int height;
    Vector2f scroll;
    bool filtering = true;

    this()
    {
        scroll = Vector2f(0, 0);
    }

    this(uint w, uint h)
    {
        scroll = Vector2f(0, 0);

        width = w;
        height = h;

        glGenTextures(1, &tex);
        glBindTexture(GL_TEXTURE_2D, tex);
        glTexImage2D(GL_TEXTURE_2D, 0, 4, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, null);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    }


    this(SuperImage img, bool genMipmaps = true)
    {
        scroll = Vector2f(0, 0);
        createFromImage(img, genMipmaps);
    }

    void createFromImage(SuperImage img, bool genMipmaps = true)
    {
        if (glIsTexture(tex))
            glDeleteTextures(1, &tex);

        width = img.width;
        height = img.height;

        glGenTextures(1, &tex);
        glBindTexture(GL_TEXTURE_2D, tex);

        if (genMipmaps)
        {
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
        }
        else
        {
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        }

        glPixelStorei(GL_UNPACK_ALIGNMENT, 1);

        type = GL_UNSIGNED_BYTE;

        switch (img.pixelFormat)
        {
            case PixelFormat.L8:     format = GL_LUMINANCE; break;
            case PixelFormat.LA8:    format = GL_LUMINANCE_ALPHA; break;
            case PixelFormat.RGB8:   format = GL_RGB; break;
            case PixelFormat.RGBA8:  format = GL_RGBA; break;
            case PixelFormat.L16:    format = GL_LUMINANCE;       type = GL_UNSIGNED_SHORT; break;
            case PixelFormat.LA16:   format = GL_LUMINANCE_ALPHA; type = GL_UNSIGNED_SHORT; break;
            case PixelFormat.RGB16:  format = GL_RGB;             type = GL_UNSIGNED_SHORT; break;
            case PixelFormat.RGBA16: format = GL_RGBA;            type = GL_UNSIGNED_SHORT; break;
            default:
                assert(0, "Texture.createFromImage is not implemented for PixelFormat " ~ img.pixelFormat.to!string);
        }

        gluBuild2DMipmaps(GL_TEXTURE_2D,
            format, width, height, format,
            type, cast(void*)img.data.ptr);
    }

    void bind(double dt)
    {
        glEnable(GL_TEXTURE_2D);
        if (glIsTexture(tex))
            glBindTexture(GL_TEXTURE_2D, tex);
        if (!filtering)
        {
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        }
        glMatrixMode(GL_TEXTURE);
        glPushMatrix();
        glLoadIdentity();
        glTranslatef(scroll.x, scroll.y, 0);
        glMatrixMode(GL_MODELVIEW);
    }

    void unbind()
    {
        glMatrixMode(GL_TEXTURE);
        glPopMatrix();
        glMatrixMode(GL_MODELVIEW);
        if (!filtering)
        {
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
        }
        glBindTexture(GL_TEXTURE_2D, 0);
        glDisable(GL_TEXTURE_2D);
    }
    
    bool valid()
    {
        return cast(bool)glIsTexture(tex);
    }

    ~this()
    {
        if (glIsTexture(tex))
            glDeleteTextures(1, &tex);
    }

    void free()
    {
        Delete(this);
    }

    void copyRendered()
    {
        glBindTexture(GL_TEXTURE_2D, tex);
        glCopyTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, 0, 0, width, height);
        glBindTexture(GL_TEXTURE_2D, 0);
    }
}

