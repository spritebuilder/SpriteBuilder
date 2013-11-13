//
//  FCFormatConverter.m
//  CocosBuilder
//
//  Created by Viktor on 6/27/13.
//
//

#import "FCFormatConverter.h"

static FCFormatConverter* gDefaultConverter = NULL;

@implementation FCFormatConverter

+ (FCFormatConverter*) defaultConverter
{
    if (!gDefaultConverter)
    {
        gDefaultConverter = [[FCFormatConverter alloc] init];
    }
    return gDefaultConverter;
}

- (NSString*) proposedNameForConvertedImageAtPath:(NSString*)srcPath format:(int)format dither:(BOOL)dither compress:(BOOL)compress
{
    if (format == kFCImageFormatPNG ||
        format == kFCImageFormatPNG_8BIT)
    {
        return [[srcPath copy] autorelease];
    }
    else if (format == kFCImageFormatPVR_RGBA8888 ||
             format == kFCImageFormatPVR_RGBA4444 ||
             format == kFCImageFormatPVR_RGB565 ||
             format == kFCImageFormatPVRTC_4BPP ||
             format == kFCImageFormatPVRTC_2BPP)
    {
        NSString* dstPath = [[srcPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"pvr"];
        if (compress) dstPath = [dstPath stringByAppendingPathExtension:@"ccz"];
        return dstPath;
    }
    else if (format == kFCImageFormatJPG_Low ||
             format == kFCImageFormatJPG_Medium ||
             format == kFCImageFormatJPG_High)
    {
        NSString* dstPath = [[srcPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"jpg"];
        return dstPath;
    }
    return NULL;
}

- (NSString*) convertImageAtPath:(NSString*)srcPath format:(int)format dither:(BOOL)dither compress:(BOOL)compress
{
    NSFileManager* fm = [NSFileManager defaultManager];
    NSString* dstDir = [srcPath stringByDeletingLastPathComponent];
    
    if (format == kFCImageFormatPNG)
    {
        // PNG image - no conversion required
        return [[srcPath copy] autorelease];
    }
    if (format == kFCImageFormatPNG_8BIT)
    {
        // 8 bit PNG image
        NSTask* pngTask = [[NSTask alloc] init];
        [pngTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"pngquant"]];
        NSMutableArray* args = [NSMutableArray arrayWithObjects:
                                @"--force", @"--ext", @".png", srcPath, nil];
        if (dither) [args addObject:@"-dither"];
        [pngTask setArguments:args];
        [pngTask launch];
        [pngTask waitUntilExit];
        [pngTask release];
        
        if ([fm fileExistsAtPath:srcPath])
        {
            return [[srcPath copy] autorelease];
        }
    }
    else if (format == kFCImageFormatPVR_RGBA8888 ||
             format == kFCImageFormatPVR_RGBA4444 ||
             format == kFCImageFormatPVR_RGB565 ||
             format == kFCImageFormatPVRTC_4BPP ||
             format == kFCImageFormatPVRTC_2BPP)
    {
        // PVR(TC) image
        NSString *dstPath = [[srcPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"pvr"];
        
        NSString* formatStr = NULL;
        if (format == kFCImageFormatPVR_RGBA8888) formatStr = @"r8g8b8a8,UBN,lRGB";
        else if (format == kFCImageFormatPVR_RGBA4444) formatStr = @"r4g4b4a4,USN,lRGB";
        else if (format == kFCImageFormatPVR_RGB565) formatStr = @"r5g6b5,USN,lRGB";
        else if (format == kFCImageFormatPVRTC_4BPP) formatStr = @"PVRTC1_4,UBN,lRGB";
        else if (format == kFCImageFormatPVRTC_2BPP) formatStr = @"PVRTC1_2,UBN,lRGB";
        
        // Convert PNG to PVR(TC)
        NSTask* pvrTask = [[NSTask alloc] init];
        [pvrTask setCurrentDirectoryPath:dstDir];
        [pvrTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"PVRTexToolCL"]];
        NSMutableArray* args = [NSMutableArray arrayWithObjects:
                                @"-i", srcPath,
                                @"-o", dstPath,
                                @"-p",
                                @"-legacypvr",
                                @"-f", formatStr,
                                @"-q", @"pvrtcbest",
                                nil];
        if (dither) [args addObject:@"-dither"];
        [pvrTask setArguments:args];
        [pvrTask launch];
        [pvrTask waitUntilExit];
        [pvrTask release];
        
        // Remove PNG file
        [[NSFileManager defaultManager] removeItemAtPath:srcPath error:NULL];
        
        if (compress)
        {
            // Create compressed file (ccz)
            NSTask* zipTask = [[NSTask alloc] init];
            [zipTask setCurrentDirectoryPath:dstDir];
            [zipTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"ccz"]];
            NSMutableArray* args = [NSMutableArray arrayWithObjects:dstPath, nil];
            [zipTask setArguments:args];
            [zipTask launch];
            [zipTask waitUntilExit];
            [zipTask release];
            
            // Remove uncompressed file
            [[NSFileManager defaultManager] removeItemAtPath:dstPath error:NULL];
            
            // Update name of texture file
            dstPath = [dstPath stringByAppendingPathExtension:@"ccz"];
        }
        
        if ([fm fileExistsAtPath:dstPath])
        {
            return dstPath;
        }
    }
    else if (format == kFCImageFormatJPG_Low ||
             format == kFCImageFormatJPG_Medium ||
             format == kFCImageFormatJPG_High)
    {
        // JPG image format
        NSString* dstPath = [[srcPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"jpg"];
        
        // Set the compression factor
        float compressionFactor = 1;
        if (format == kFCImageFormatJPG_High) compressionFactor = 0.9;
        else if (format == kFCImageFormatJPG_Medium) compressionFactor = 0.6;
        else if (format == kFCImageFormatJPG_Low) compressionFactor = 0.3;
        
        NSDictionary* props = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:compressionFactor] forKey:NSImageCompressionFactor];
        
        // Convert the file
        NSBitmapImageRep* imageRep = [NSBitmapImageRep imageRepWithContentsOfFile:srcPath];
        NSData* imgData = [imageRep representationUsingType:NSJPEGFileType properties:props];
        
        if (![imgData writeToFile:dstPath atomically:YES]) return NULL;
        
        // Remove old file
        if (![srcPath isEqualToString:dstPath])
        {
            [fm removeItemAtPath:srcPath error:NULL];
        }
        
        return dstPath;
        
        return NULL;
    }
    
    // Conversion failed
    return NULL;
}

- (NSString*) proposedNameForConvertedSoundAtPath:(NSString*)srcPath format:(int)format quality:(int)quality
{
    NSString* ext = NULL;
    if (format == kFCSoundFormatCAF) ext = @"caf";
    else if (format == kFCSoundFormatMP4) ext = @"m4a";
    else if (format == kFCSoundFormatOGG) ext = @"ogg";
    
    if (ext)
    {
        return [[srcPath stringByDeletingPathExtension] stringByAppendingPathExtension:ext];
    }
    return NULL;
}

- (NSString*) convertSoundAtPath:(NSString*)srcPath format:(int)format quality:(int)quality
{
    NSString* dstPath = [self proposedNameForConvertedSoundAtPath:srcPath format:format quality:quality];
    NSFileManager* fm = [NSFileManager defaultManager];
    
    if (format == kFCSoundFormatCAF)
    {
        // Convert to CAF
        NSTask* sndTask = [[NSTask alloc] init];
        
        [sndTask setLaunchPath:@"/usr/bin/afconvert"];
        NSMutableArray* args = [NSMutableArray arrayWithObjects:
                                @"-f", @"caff",
                                @"-d", @"LEI16@44100",
                                @"-c", @"1",
                                srcPath, dstPath, nil];
        [sndTask setArguments:args];
        [sndTask launch];
        [sndTask waitUntilExit];
        
        [sndTask release];
        
        // Remove old file
        if (![srcPath isEqualToString:dstPath])
        {
            [fm removeItemAtPath:srcPath error:NULL];
        }
        
        return dstPath;
    }
    else if (format == kFCSoundFormatMP4)
    {
        // Convert to AAC
        
        int qualityScaled = ((quality -1) * 127) / 7;//Quality [1,8]
        
        // Do the conversion
        NSTask* sndTask = [[NSTask alloc] init];
        
        [sndTask setLaunchPath:@"/usr/bin/afconvert"];
        NSMutableArray* args = [NSMutableArray arrayWithObjects:
                                @"-f", @"m4af",
                                @"-d", @"aac",
                                @"-u", @"pgcm", @"2",
                                @"-u", @"vbrq", [NSString stringWithFormat:@"%i",qualityScaled],
                                @"-q", @"127",
                                @"-s", @"3",
                                srcPath, dstPath, nil];
        [sndTask setArguments:args];
        [sndTask launch];
        [sndTask waitUntilExit];
        
        [sndTask release];
        
        // Remove old file
        if (![srcPath isEqualToString:dstPath])
        {
            [fm removeItemAtPath:srcPath error:NULL];
        }
        
        return dstPath;
    }
    else if (format == kFCSoundFormatOGG)
    {
        // Convert to OGG
        NSTask* sndTask = [[NSTask alloc] init];
        [sndTask setCurrentDirectoryPath:[srcPath stringByDeletingLastPathComponent]];
        [sndTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"oggenc"]];
        NSMutableArray* args = [NSMutableArray arrayWithObjects:
                                [NSString stringWithFormat:@"-q%d", quality],
                                @"-o", dstPath, srcPath,
                                nil];
        [sndTask setArguments:args];
        [sndTask launch];
        [sndTask waitUntilExit];
        [sndTask release];

        // Remove old file
        if (![srcPath isEqualToString:dstPath])
        {
            [fm removeItemAtPath:srcPath error:NULL];
        }
        
        return dstPath;
    }
    
    return NULL;
}

@end
