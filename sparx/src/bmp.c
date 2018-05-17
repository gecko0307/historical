/*
 * Copyright (c) 2005-2007 David HENRY
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR
 * ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 * CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#include <stdio.h>
#include <stdlib.h>

#include "image.h"

#pragma pack(push, 2)
/* Bitmap file header */
struct bmp_file_header_t
{
  unsigned char bfType[2];      /* magic number "BM" */
  unsigned int bfSize;          /* file size */
  unsigned short bfReserved1;
  unsigned short bfReserved2;
  unsigned int bfOffBits;       /* offset to image data */
};
#pragma pack(pop)

/* Bitmap info header */
struct bmp_info_header_t
{
  unsigned int biSize;          /* size of bitmap info header */
  int biWidth;                  /* image with */
  int biHeight;                 /* image height */
  unsigned short biPlanes;      /* must be equal to 1 */
  unsigned short biBitCount;    /* bits per pixels */
  unsigned int biCompression;   /* compression type */
  unsigned int biSizeImage;     /* size of pixel data */
  int biXPelsPerMeter;          /* pixels per meter on x-axis */
  int biYPelsPerMeter;          /* pixels per meter on y-axis */
  unsigned int biClrUsed;       /* number of used colors */
  unsigned int biClrImportant;  /* number of important colors */
};

/* Bitmap core header */
struct bmp_core_header_t
{
  unsigned int bcSize;           /* size of bitmap core header */
  unsigned short bcWidth;        /* image with */
  unsigned short bcHeight;       /* image height */
  unsigned short bcPlanes;       /* must be equal to 1 */
  unsigned short bcBitCount;     /* bits per pixel */
};

/* Bitmap core info */
struct bmp_core_info_t
{
  struct bmp_core_header_t bmciHeader;
  unsigned char bmciColors[3];
};

/* OS-style type */
enum os_type_e
{
    BMP_WIN,
    BMP_OS2,
};

enum compression_type_e
{
    /* BMP compression type constants */
    BI_RGB          = 0,
    BI_RLE8         = 1,
    BI_RLE4         = 2,
    BI_BITFIELDS    = 3,

    /* RLE byte type constants */
    RLE_COMMAND     = 0,
    RLE_ENDOFLINE   = 0,
    RLE_ENDOFBITMAP = 1,
    RLE_DELTA       = 2,
};

void ReadBMP1bit (FILE *fp, const unsigned char *colormap,
	     enum os_type_e os_type, struct image_t *texinfo)
{
  int i, j, cmPixSize;
  unsigned char color, clrIndex;

  cmPixSize = (os_type == BMP_OS2) ? 3 : 4;

  for (i = 0; i < texinfo->width * texinfo->height; )
    {
      /* Read index color byte */
      color = (unsigned char)fgetc( fp );

      /* Convert 8-by-8 pixels to RGB 24 bits */
      for (j = 7; j >= 0; --j, ++i)
	{
	  clrIndex = ((color & (1 << j)) > 0);
	  texinfo->texels[(i * 3) + 2] = colormap[(clrIndex * cmPixSize) + 0];
	  texinfo->texels[(i * 3) + 1] = colormap[(clrIndex * cmPixSize) + 1];
	  texinfo->texels[(i * 3) + 0] = colormap[(clrIndex * cmPixSize) + 2];
	}
    }
}

void ReadBMP4bits (FILE *fp, const unsigned char *colormap,
	      enum os_type_e os_type, struct image_t *texinfo)
{
  int i, cmPixSize;
  unsigned char color, clrIndex;

  cmPixSize = (os_type == BMP_OS2) ? 3 : 4;

  for (i = 0; i < texinfo->width * texinfo->height; i += 2)
    {
      /* Read index color byte */
      color = (unsigned char)fgetc (fp);

      /* Convert 2-by-2 pixels to RGB 24 bits */

      /* First pixel */
      clrIndex = (color >> 4);
      texinfo->texels[(i * 3) + 2] = colormap[(clrIndex * cmPixSize) + 0];
      texinfo->texels[(i * 3) + 1] = colormap[(clrIndex * cmPixSize) + 1];
      texinfo->texels[(i * 3) + 0] = colormap[(clrIndex * cmPixSize) + 2];

      /* second pixel */
      clrIndex = (color & 0x0F);
      texinfo->texels[(i * 3) + 5] = colormap[(clrIndex * cmPixSize) + 0];
      texinfo->texels[(i * 3) + 4] = colormap[(clrIndex * cmPixSize) + 1];
      texinfo->texels[(i * 3) + 3] = colormap[(clrIndex * cmPixSize) + 2];
    }
}

void ReadBMP8bits (FILE *fp, const unsigned char *colormap,
	      enum os_type_e os_type, struct image_t *texinfo)
{
  int i, cmPixSize;
  unsigned char color;

  cmPixSize = (os_type == BMP_OS2) ? 3 : 4;

  for (i = 0; i < texinfo->width * texinfo->height; ++i)
    {
      /* Read index color byte */
      color = (unsigned char)fgetc (fp);

      /* Convert to RGB 24 bits */
      texinfo->texels[(i * 3) + 2] = colormap[(color * cmPixSize) + 0];
      texinfo->texels[(i * 3) + 1] = colormap[(color * cmPixSize) + 1];
      texinfo->texels[(i * 3) + 0] = colormap[(color * cmPixSize) + 2];
    }
}

void ReadBMP24bits (FILE *fp, struct image_t *texinfo)
{
  int i;

  for (i = 0; i < texinfo->width * texinfo->height; ++i)
    {
      /* Read and convert BGR to RGB */
      texinfo->texels[(i * 3) + 2] = (unsigned char)fgetc (fp);
      texinfo->texels[(i * 3) + 1] = (unsigned char)fgetc (fp);
      texinfo->texels[(i * 3) + 0] = (unsigned char)fgetc (fp);
    }
}

void ReadBMP32bits (FILE *fp, struct image_t *texinfo)
{
  int i;
  unsigned char skip;

  for (i = 0; i < texinfo->width * texinfo->height; ++i)
    {
      /* Read and convert BGRA to RGB */
      texinfo->texels[(i * 3) + 2] = (unsigned char)fgetc (fp);
      texinfo->texels[(i * 3) + 1] = (unsigned char)fgetc (fp);
      texinfo->texels[(i * 3) + 0] = (unsigned char)fgetc (fp);

      /* Skip last byte */
      skip = (unsigned char)fgetc (fp);
    }
}

void ReadBMP8bitsRLE (FILE *fp, const unsigned char *colormap,
		 struct image_t *texinfo)
{
  int i;
  unsigned char color, skip;
  unsigned char byte1, byte2;
  unsigned char *ptr = texinfo->texels;

  while (ptr < texinfo->texels + (texinfo->width * texinfo->height) * 3)
    {
      /* Read first two byte */
      byte1 = (unsigned char)fgetc (fp);
      byte2 = (unsigned char)fgetc (fp);

      if (byte1 == RLE_COMMAND)
	{
	  for (i = 0; i < byte2; ++i, ptr += 3)
	    {
	      color = (unsigned char)fgetc (fp);

	      ptr[0] = colormap[(color * 4) + 2];
	      ptr[1] = colormap[(color * 4) + 1];
	      ptr[2] = colormap[(color * 4) + 0];
	    }

	  if (byte2 % 2)
	    {
	      /* Skip one byte if number of pixels is odd */
	      skip = (unsigned char)fgetc (fp);
	    }
	}
      else
	{
	  for (i = 0; i < byte1; ++i, ptr += 3)
	    {
	      ptr[0] = colormap[(byte2 * 4) + 2];
	      ptr[1] = colormap[(byte2 * 4) + 1];
	      ptr[2] = colormap[(byte2 * 4) + 0];
	    }
	}
    }
}

void ReadBMP4bitsRLE (FILE *fp, const unsigned char *colormap,
		 struct image_t *texinfo)
{
  int i, bytesRead = 0;
  unsigned char color, databyte, skip;
  unsigned char byte1, byte2;
  unsigned char *ptr = texinfo->texels;

  while (ptr < texinfo->texels + (texinfo->width * texinfo->height) * 3)
    {
      /* Read first two byte */
      byte1 = (unsigned char)fgetc (fp);
      byte2 = (unsigned char)fgetc (fp);
      bytesRead += 2;

      if (byte1 == RLE_COMMAND)
	{
	  databyte = 0;

	  for (i = 0; i < byte2; ++i, ptr += 3)
	    {
	      if (i % 2)
		{
		  /* Four less significant bits */
		  color = (databyte & 0x0F);
		}
	      else
		{
		  databyte = (unsigned char)fgetc (fp);
		  ++bytesRead;

		  /* Four most significant bits */
		  color = (databyte >> 4);
		}

	      /* Convert from index color to RGB 24 bits */
	      ptr[0] = colormap[(color * 4) + 2];
	      ptr[1] = colormap[(color * 4) + 1];
	      ptr[2] = colormap[(color * 4) + 0];
	    }

	  if (bytesRead % 2)
	    {
	      /* Skip one byte if number of read bytes is odd */
	      skip = (unsigned char)fgetc (fp);
	      ++bytesRead;
	    }
	}
      else
	{
	  for (i = 0; i < byte1; ++i, ptr += 3)
	    {
	      if (i % 2)
		color = (byte2 & 0x0F);
	      else
		color = (byte2 >> 4);

	      /* Convert from index color to RGB 24 bits */
	      ptr[0] = colormap[(color * 4) + 2];
	      ptr[1] = colormap[(color * 4) + 1];
	      ptr[2] = colormap[(color * 4) + 0];
	    }
	}
    }
}

int ImageBMPRead(const char *filename, struct image_t * texinfo)
{
  FILE *fp;
  /* struct image_t *texinfo; */
  struct bmp_file_header_t bmfh;
  struct bmp_info_header_t bmih;
  struct bmp_core_header_t bmch;
  enum os_type_e os_type;
  unsigned int compression;
  unsigned int bitCount;
  fpos_t bmhPos;
  unsigned char *colormap = NULL;
  int colormapSize;

  fp = fopen (filename, "rb");
  if (!fp)
    {
      fprintf (stderr, "error: couldn't open \"%s\"!\n", filename);
      return 0;
    }

  /* Read bitmap file header */
  fread (&bmfh, sizeof (struct bmp_file_header_t), 1, fp);
  fgetpos (fp, &bmhPos);

  if (strncmp ((char *)bmfh.bfType, "BM", 2) != 0)
    {
      fprintf (stderr, "%s is not a valid BMP file!\n", filename);
      fclose (fp);
      return 0;
    }

  /* Allocate memory for texture info and init some parameters */
  /* texinfo = (struct image_t *)
    malloc (sizeof (struct image_t)); */
  texinfo->format = GL_RGB;
  texinfo->internalFormat = 3;

  /* Read bitmap info header */
  fread (&bmih, sizeof (struct bmp_info_header_t), 1, fp);

  if (bmih.biCompression > 3)
    {
      /* This is an OS/2 bitmap file, we don't use
	 bitmap info header but bitmap core header instead */

      /* We must go back to read bitmap core header */
      fsetpos (fp, &bmhPos);
      fread (&bmch, sizeof (struct bmp_core_header_t), 1, fp);

      os_type = BMP_OS2;
      compression = BI_RGB;
      bitCount = bmch.bcBitCount;

      texinfo->width = bmch.bcWidth;
      texinfo->height = bmch.bcHeight;
    }
  else
    {
      /* Windows style */
      compression = bmih.biCompression;
      os_type = BMP_WIN;
      bitCount = bmih.biBitCount;

      texinfo->width = bmih.biWidth;
      texinfo->height = bmih.biHeight;
    }

  /* Look for palette data if present */
  if (bitCount <= 8)
    {
      colormapSize = (1 << bitCount) * ((os_type == BMP_OS2) ? 3 : 4);
      colormap = (unsigned char *)malloc (colormapSize * sizeof (unsigned char));

      fread (colormap, sizeof (unsigned char), colormapSize, fp);
    }

  /* Memory allocation for pixel data */
  texinfo->texels = (unsigned char *)malloc (texinfo->width
	       * texinfo->height * texinfo->internalFormat);

  /* Go to begining of pixel data */
  fseek (fp, bmfh.bfOffBits, SEEK_SET);

  /* Read image data */
  switch (compression)
    {
    case BI_RGB:
      switch (bitCount)
	{
	case 1:
	  ReadBMP1bit (fp, colormap, os_type, texinfo);
	  break;

	case 4:
	  ReadBMP4bits (fp, colormap, os_type, texinfo);
	  break;

	case 8:
	  ReadBMP8bits (fp, colormap, os_type, texinfo);
	  break;

	case 24:
	  ReadBMP24bits (fp, texinfo);
	  break;

	case 32:
	  ReadBMP32bits (fp, texinfo);
	  break;
	}

      break;

    case BI_RLE8:
      ReadBMP8bitsRLE (fp, colormap, texinfo);
      break;

    case BI_RLE4:
      ReadBMP4bitsRLE (fp, colormap, texinfo);
      break;

    case BI_BITFIELDS:
    default:
      /* Unsupported file types */
      fprintf (stderr, "unsupported bitmap type or bad file"
	       "compression type (%i)\n", compression);
      free (texinfo->texels);
      /*free (texinfo);
      texinfo = NULL;*/
      break;
    }

  /* No longer need colormap data */
  if (colormap)
    free (colormap);

  fclose (fp);
  return 1;
}
