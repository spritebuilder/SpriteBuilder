
/*
 * CocosBuilder: http://www.cocosbuilder.com
 *
 * Copyright (c) 2012 Zynga Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "Tupac.h"
#import "FCFormatConverter.h"
#import "FCFormatConverter.h"
#import "MaxRectsBinPack.h"
#import "vector"

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CGImage.h>

#import "pvrtc.h"

unsigned long upper_power_of_two(unsigned long v)
{
    v--;
    v |= v >> 1;
    v |= v >> 2;
    v |= v >> 4;
    v |= v >> 8;
    v |= v >> 16;
    v++;
    return v;
}

typedef struct _PVRTexHeader
{
    uint32_t headerLength;
    uint32_t height;
    uint32_t width;
    uint32_t numMipmaps;
    uint32_t flags;
    uint32_t dataLength;
    uint32_t bpp;
    uint32_t bitmaskRed;
    uint32_t bitmaskGreen;
    uint32_t bitmaskBlue;
    uint32_t bitmaskAlpha;
    uint32_t pvrTag;
    uint32_t numSurfs;
} PVRTexHeader;


@interface Tupac ()
@property (nonatomic, strong) FCFormatConverter *formatConverter;
@end

@implementation Tupac {
    BOOL cancelled_;
}

@synthesize scale=scale_, border=border_, filenames=filenames_, outputName=outputName_, outputFormat=outputFormat_, imageFormat=imageFormat_, directoryPrefix=directoryPrefix_, maxTextureSize=maxTextureSize_, padding=padding_, dither=dither_, compress=compress_;
@synthesize errorMessage;

+ (Tupac*) tupac
{
    return [[Tupac alloc] init];
}

- (id)init
{
    if ((self = [super init]))
    {
        scale_ = 1.0;
        border_ = NO;
        cancelled_ = NO;
        imageFormat_ = kFCImageFormatPNG;
        self.outputFormat = TupacOutputFormatCocos2D;
        self.maxTextureSize = 2048;
        self.padding = 1;
    }
    return self;
}


- (void)setErrorMessage:(NSString *)em
{
    if (em != errorMessage)
    {
        errorMessage = em;
    }
}

+ (NSRect) trimmedRectForImage:(CGImageRef)image
{
    int w = (int)CGImageGetWidth(image);
    int h = (int)CGImageGetHeight(image);
    
    int bytesPerRow = (int)CGImageGetBytesPerRow(image);
    int pixelsPerRow = bytesPerRow/4;
    
    CGImageGetDataProvider((CGImageRef)image);
    CFDataRef imageData = CGDataProviderCopyData(CGImageGetDataProvider(image));
    const UInt32 *pixels = (const UInt32*)CFDataGetBytePtr(imageData);
    
    // Search from left
    int x;
    for (x = 0; x < w; x++)
    {
        BOOL emptyRow = YES;
        for (int y = 0; y < h; y++)
        {
            if (pixels[y*pixelsPerRow+x] & 0xff000000)
            {
                emptyRow = NO;
            }
        }
        if (!emptyRow) break;
    }
    
    // Search from right
    int xRight;
    for (xRight = w-1; xRight >= 0; xRight--)
    {
        BOOL emptyRow = YES;
        for (int y = 0; y < h; y++)
        {
            if (pixels[y*pixelsPerRow+xRight] & 0xff000000)
            {
                emptyRow = NO;
            }
        }
        if (!emptyRow) break;
    }
    
    // Search from bottom
    int y;
    for (y = 0; y < h; y++)
    {
        BOOL emptyRow = YES;
        for (int x = 0; x < w; x++)
        {
            if (pixels[y*pixelsPerRow+x] & 0xff000000)
            {
                emptyRow = NO;
            }
        }
        if (!emptyRow) break;
    }
    
    // Search from top
    int yTop;
    for (yTop = h-1; yTop >=0; yTop--)
    {
        BOOL emptyRow = YES;
        for (int x = 0; x < w; x++)
        {
            if (pixels[yTop*pixelsPerRow+x] & 0xff000000)
            {
                emptyRow = NO;
            }
        }
        if (!emptyRow) break;
    }
    
    int wTrimmed = xRight-x+1;
    int hTrimmed = yTop-y+1;
    
    CFRelease(imageData);
    
    return NSMakeRect(x, y, wTrimmed, hTrimmed);
}

- (NSArray *)createTextureAtlas
{
    // Reset the error message
    if (errorMessage)
    {
        errorMessage = NULL;
    }

    NSMutableArray *result = [NSMutableArray array];

    // Create output directory if it doesn't exist
    NSFileManager* fm = [NSFileManager defaultManager];
    NSString* outputDir = [outputName_ stringByDeletingLastPathComponent];
    if (![fm fileExistsAtPath:outputDir])
    {
        [fm createDirectoryAtPath:outputDir withIntermediateDirectories:YES attributes:NULL error:NULL];
    }
    
    // Load images and retrieve information about them
    NSMutableArray *images = [NSMutableArray arrayWithCapacity:self.filenames.count];
    NSMutableArray *imageInfos = [NSMutableArray arrayWithCapacity:self.filenames.count];
    
    CGColorSpaceRef colorSpace = NULL;
    BOOL createdColorSpace = NO;
        
    for (NSString *filename in self.filenames)
    {
        if (cancelled_)
        {
            return nil;
        }

        // Load CGImage
        CGImageSourceRef image_source = CGImageSourceCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:filename], NULL);
        CGImageRef srcImage = CGImageSourceCreateImageAtIndex(image_source, 0, NULL);
        
        // Get info
        int w = (int)CGImageGetWidth(srcImage);
        int h = (int)CGImageGetHeight(srcImage);
        
        NSRect trimRect = [Tupac trimmedRectForImage:srcImage];
        
        if (!colorSpace)
        {
            colorSpace = CGImageGetColorSpace(srcImage);
        
            if (CGColorSpaceGetModel(colorSpace) == kCGColorSpaceModelIndexed)
            {
                colorSpace = CGColorSpaceCreateDeviceRGB();
                createdColorSpace = YES;
            }
        }
        
        NSMutableDictionary* imageInfo = [NSMutableDictionary dictionary];
        [imageInfo setObject:[NSNumber numberWithInt:w] forKey:@"width"];
        [imageInfo setObject:[NSNumber numberWithInt:h] forKey:@"height"];
        [imageInfo setObject:[NSValue valueWithRect:trimRect] forKey:@"trimRect"];
        
        // Store info info
        [imageInfos addObject:imageInfo];
        [images addObject:[NSValue valueWithPointer:srcImage]];
        
        // Relase objects (images released later)
        CFRelease(image_source);
    }
    
    // Check that the output format is valid
    if (![self.outputFormat isEqualToString:TupacOutputFormatCocos2D]
        && ![self.outputFormat isEqualToString:TupacOutputFormatAndEngine]) {
        fprintf(stderr, "unknown output format %s\n", [self.outputFormat UTF8String]);
        exit(EXIT_FAILURE);
    }

    // Find the longest side
    int maxSideLen = 8;
    for (NSDictionary* imageInfo in imageInfos)
    {
        NSRect trimRect = [[imageInfo objectForKey:@"trimRect"] rectValue];
        
        int w = trimRect.size.width;
        if (w > maxSideLen) maxSideLen = w + self.padding * 2;
        
        int h = trimRect.size.height;
        if (h > maxSideLen) maxSideLen = h + self.padding * 2;
    }
    maxSideLen = upper_power_of_two(maxSideLen);
    
    // Pack using max rects
    int outW = maxSideLen;
    int outH = 8;
    
    std::vector<TPRect> outRects;
    
    BOOL makeSquare = NO;
    if (self.imageFormat == kFCImageFormatPVRTC_2BPP || self.imageFormat == kFCImageFormatPVRTC_4BPP)
    {
        makeSquare = YES;
        outH = outW;
    }
    
    BOOL allFitted = NO;
    BOOL packingError = NO;
    while (!packingError && !allFitted)
    {
        MaxRectsBinPack bin(outW, outH);
        
        std::vector<TPRectSize> inRects;
        
        int numImages = 0;
        for (NSDictionary* imageInfo in imageInfos)
        {
            NSRect trimRect = [[imageInfo objectForKey:@"trimRect"] rectValue];
            
            inRects.push_back(TPRectSize());
            inRects[numImages].width = trimRect.size.width + self.padding * 2;
            inRects[numImages].height = trimRect.size.height + self.padding * 2;
            inRects[numImages].idx = numImages;
            
            numImages++;
        }
       
        bin.Insert(inRects, outRects, MaxRectsBinPack::RectBestShortSideFit);
        
        if (numImages == (int)outRects.size())
        {
            allFitted = YES;
        }
        else
        {
            if (makeSquare)
            {
                outW *= 2;
                outH *= 2;
            }
            else
            {
                if (outW > outH)
                    outH *= 2;
                else
                    outW *= 2;
            }
            
            if (outW > self.maxTextureSize)
                packingError = YES;
        }
    }
    
    if (packingError)
    {
        [self setErrorMessage:@"Failed to fit all sprites in smart sprite sheet."];
    }
    
    // Create the output graphics context
    CGContextRef dstContext = CGBitmapContextCreate(NULL, outW, outH, 8, outW*32, colorSpace, kCGImageAlphaPremultipliedLast);
	NSAssert(dstContext != nil, @"CG bitmap context is nil");

    // Draw all the individual images
    int index = 0;
    while (index < outRects.size())
    {
        if (cancelled_)
        {
            return nil;
        }
        
        bool rot = false;
        int  x, y, w, h;
        
        // Get the image and info
        CGImageRef srcImage = (CGImageRef)[[images objectAtIndex:outRects[index].idx] pointerValue];
        NSDictionary* imageInfo = [imageInfos objectAtIndex:outRects[index].idx];
        
        x = outRects[index].x;
        y = outRects[index].y;
       
        rot = outRects[index].rotated;
        
        x += self.padding;
        y += self.padding;
        
        NSRect trimRect = [[imageInfo objectForKey:@"trimRect"] rectValue];
        if (rot)
        {
            h = [[imageInfo objectForKey:@"width"] intValue];
            w = [[imageInfo objectForKey:@"height"] intValue];
            
            x -= (w - trimRect.origin.y - trimRect.size.height);
            y -= trimRect.origin.x;
        }
        else
        {
            w = [[imageInfo objectForKey:@"width"] intValue];
            h = [[imageInfo objectForKey:@"height"] intValue];
            
            x -= trimRect.origin.x;
            y -= trimRect.origin.y;
        }
        
        if (rot)
        {
            // Rotate image 90 degrees
            CGContextRef rotContext = CGBitmapContextCreate(NULL, w, h, 8, 32*w, colorSpace, kCGImageAlphaPremultipliedLast);
            CGContextSaveGState(rotContext);
            CGContextRotateCTM(rotContext, -M_PI/2);
            CGContextTranslateCTM(rotContext, -h, 0);
            CGContextDrawImage(rotContext, CGRectMake(0, 0, h, w), srcImage);
            
            CGImageRelease(srcImage);
            srcImage = CGBitmapContextCreateImage(rotContext);
            CFRelease(rotContext);
        }
        
        // Draw the image
        CGContextDrawImage(dstContext, CGRectMake(x, outH-y-h, w, h), srcImage);
        
        // Release the image
        CGImageRelease(srcImage);
        
        index++;
    }
    
    [NSGraphicsContext restoreGraphicsState];

    if (cancelled_)
    {
        return nil;
    }
    
    NSString* textureFileName = NULL;
    
    // Export PNG file
    
    NSString *pngFilename  = [self.outputName stringByAppendingPathExtension:@"png"];
    
    CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:pngFilename];
    CGImageRef imageDst = CGBitmapContextCreateImage(dstContext);
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, NULL);
    CGImageDestinationAddImage(destination, imageDst, nil);
    
    if (!CGImageDestinationFinalize(destination)) {
        NSLog(@"Failed to write image to %@", pngFilename);
    }
    
    CGImageRelease(imageDst);
    CGContextRelease(dstContext);
    
    textureFileName = pngFilename;
    
    if (createdColorSpace)
    {
        CFRelease(colorSpace);
    }
    
    [self generatePreviewImage:pngFilename];

    NSError * error = nil;

    self.formatConverter = [FCFormatConverter defaultConverter];
    if(![_formatConverter convertImageAtPath:pngFilename
                                      format:imageFormat_
                                      dither:dither_
                                    compress:compress_
                               isSpriteSheet:YES
                              outputFilename:&textureFileName
                                       error:&error])
    {
        [self setErrorMessage:error.localizedDescription];
    }
    self.formatConverter = nil;

    if (cancelled_)
    {
        return nil;
    }

    [result addObject:textureFileName];

    // Metadata File Export
    textureFileName = [textureFileName lastPathComponent];
    
    if ([self.outputFormat isEqualToString:TupacOutputFormatCocos2D])
    {
        NSMutableDictionary *outDict    = [[NSMutableDictionary alloc] initWithCapacity:2];
        
        NSMutableDictionary *frames     = [NSMutableDictionary dictionaryWithCapacity:self.filenames.count];
        NSMutableDictionary *metadata   = [NSMutableDictionary dictionaryWithCapacity:4];
        
        [outDict setObject:frames   forKey:@"frames"];
        [outDict setObject:metadata forKey:@"metadata"];
        
        int index = 0;
        while(index < outRects.size())
        {
            // Get info about the image
            NSString* filename = [self.filenames objectAtIndex:outRects[index].idx];
            NSString* exportFilename = [filename lastPathComponent];
            if (directoryPrefix_) exportFilename = [directoryPrefix_ stringByAppendingPathComponent:exportFilename];
            NSDictionary* imageInfo = [imageInfos objectAtIndex:outRects[index].idx];
            
            bool rot = false;
            int x, y, w, h, wSrc, hSrc, xOffset, yOffset;
            x = outRects[index].x + self.padding;
            y = outRects[index].y + self.padding;
            w = outRects[index].width - self.padding*2;
            h = outRects[index].height - self.padding*2;
            wSrc = [[imageInfo objectForKey:@"width"] intValue];
            hSrc = [[imageInfo objectForKey:@"height"] intValue];
            NSRect trimRect = [[imageInfo objectForKey:@"trimRect"] rectValue];
            
            rot = outRects[index].rotated;
            
            if (rot)
            {
                int wRot = h;
                int hRot = w;
                w = wRot;
                h = hRot;
            }
            
            xOffset = trimRect.origin.x + trimRect.size.width/2 - wSrc/2;
            yOffset = -trimRect.origin.y - trimRect.size.height/2 + hSrc/2;
            
            index++;
            
            [frames setObject:[NSDictionary dictionaryWithObjectsAndKeys:
                               NSStringFromRect(NSMakeRect(x, y, w, h)),    @"frame",
                               NSStringFromPoint(NSMakePoint(xOffset, yOffset)),        @"offset",
                               [NSNumber numberWithBool:rot],               @"rotated",
                               NSStringFromRect(trimRect),                  @"sourceColorRect",
                               NSStringFromSize(NSMakeSize(wSrc, hSrc)),    @"sourceSize",
                               nil]
                       forKey:exportFilename];
        }
        
        [metadata setObject:textureFileName                                     forKey:@"textureFileName"];
        [metadata setObject:[NSNumber numberWithInt:2]                      forKey:@"format"];
        [metadata setObject:NSStringFromSize(NSMakeSize(outW, outH))        forKey:@"size"];

        NSString *plistFilename = [self.outputName stringByAppendingPathExtension:@"plist"];
        [outDict writeToFile:plistFilename atomically:YES];
        [result addObject:plistFilename];
    }
    else if ([self.outputFormat isEqualToString:TupacOutputFormatAndEngine]) {
        fprintf(stderr, "[MO] output format %s not yet supported\n", [self.outputFormat UTF8String]);
        exit(EXIT_FAILURE);
    }
    return result;
}

- (void)generatePreviewImage:(NSString *)pngFilename
{
    if (self.previewFile)
    {
        NSError *error;
        if (![[NSFileManager defaultManager] removeItemAtPath:self.previewFile error:&error])
        {
            NSLog(@"[TEXTUREPACKER] Error removing preview image %@: %@", self.previewFile, error);
        }

        error = nil;
        if (![[NSFileManager defaultManager] copyItemAtPath:pngFilename toPath:self.previewFile error:&error])
        {
            NSLog(@"[TEXTUREPACKER] Error copying preview image from %@ to %@: %@", pngFilename, self.previewFile, error);
        }
    }
}

- (NSArray *) createTextureAtlasFromDirectoryPaths:(NSArray *)dirs
{
    NSFileManager* fm = [NSFileManager defaultManager];
    
    // Build a list of all file names from all directories
    NSMutableSet* allFiles = [NSMutableSet set];
    
    for (NSString* dir in dirs)
    {
        NSArray* files = [fm contentsOfDirectoryAtPath:dir error:NULL];

        if (cancelled_)
        {
            return nil;
        }

        for (NSString* file in files)
        {
				    NSString *lower = [[file pathExtension] lowercaseString];
            if ([lower isEqualToString:@"png"] || [lower isEqualToString:@"psd"])
            {
                [allFiles addObject:[file lastPathComponent]];
            }
        }
    }
    
    // Add all the absolute file names to an array from the correct directories
    NSMutableArray* absoluteFilepaths = [NSMutableArray array];
    for (NSString* file in allFiles)
    {
        for (NSString* dir in dirs)
        {
            NSString* absFilepath = [dir stringByAppendingPathComponent:file];
            
            if ([fm fileExistsAtPath:absFilepath])
            {
                [absoluteFilepaths addObject:absFilepath];
                //foundFile = YES;
                break;
            }
        }
    }
    
    // Generate the sprite sheet
    self.filenames = absoluteFilepaths;
    return [self createTextureAtlas];
}

- (void)cancel
{
    [_formatConverter cancel];
    cancelled_ = YES;
}

@end

NSString *TupacOutputFormatCocos2D = @"cocos2d";
NSString *TupacOutputFormatAndEngine = @"andengine";
