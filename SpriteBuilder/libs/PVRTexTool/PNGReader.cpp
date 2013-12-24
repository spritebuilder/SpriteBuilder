#include "png.h"
#include <stdio.h>
#include <iostream>
#include "PNGReader.h"


PNGReader::PNGReader(const char* filepath) :  png_(0), info_(0), channels_(0)
{
    FILE* fp = fopen(filepath, "rb");
    if (!fp)
    {
        std::cout << "Input file not found: " << filepath << std::endl;
        return;
    }

    png_ = png_create_read_struct(PNG_LIBPNG_VER_STRING, 0, 0, 0);
    if(!png_)
    {
        std::cout << "Internal Error: " << filepath << std::endl;
        return;
    }
    info_ = png_create_info_struct(png_);
    if(!info_)
    {
        std::cout << "Internal Error: " << filepath << std::endl;
        return;
    }
    end_ = png_create_info_struct(png_);
    if(!end_)
    {
        std::cout << "Internal Error: " << filepath << std::endl;
        return;
    }
    png_init_io(png_, fp);
    png_read_info(png_, info_);
    if (png_get_color_type(png_, info_) == PNG_COLOR_TYPE_PALETTE)
    {
        png_set_palette_to_rgb(png_);
        if (png_get_valid(png_, info_, PNG_INFO_tRNS))
        {
            png_set_tRNS_to_alpha(png_);
            channels_ = 4;
        }
        else
        {
            channels_ = 3;
        }
    }
    else if (png_get_color_type(png_, info_) == PNG_COLOR_TYPE_GRAY)
    {
        std::cout << "gray scale color" << std::endl;
        png_set_gray_to_rgb(png_);
        if (png_get_valid(png_, info_, PNG_INFO_tRNS))
        {
            std::cout << "it has transparent information" << std::endl;
            png_set_tRNS_to_alpha(png_);
            channels_ = 4;
        }
        else
        {
            channels_ = 3;
        }
    }
    else
    {
        int bitdepth = png_get_bit_depth(png_, info_);
        if (bitdepth == 16)
        {
            png_set_strip_16(png_);
        }
        else if ((bitdepth < 8) || (png_get_valid(png_, info_, PNG_INFO_tRNS)))
        {
            png_set_expand(png_);
        }
        channels_ = png_get_channels(png_, info_);
    }

    width_ = png_get_image_width(png_, info_);
    height_ = png_get_image_height(png_, info_);

    //alloc(channels_);
    data_ = (png_bytep)malloc(channels_ * width_ * height_);
    rows_ = new png_bytep [height_];
    for (size_t i = 0; i < height_; ++i)
    {
        rows_[i] = data_ + (i * width_ * channels_);
    }
    
    png_read_image(png_, rows_);
    png_read_end(png_, NULL);

    checkHasAlpha();

    valid_ = true;
}

void PNGReader::checkHasAlpha() {
    hasAlpha_ = false;
    if (channels_ == 3)
    {
        return;
    }
    for (size_t y = 0; y < height_; y++)
    {
        png_bytep row = rows_[y];

        for (size_t x = 0; x < width_; x++)
        {
            if (row[x * 4 + 3] != (png_byte)255)
            {
                hasAlpha_ = true;
                return;
            }
        }
    }
}

PNGReader::~PNGReader()
{
    destroy();
}

void PNGReader::destroy()
{
    png_destroy_read_struct(&png_, &info_, NULL);
}
