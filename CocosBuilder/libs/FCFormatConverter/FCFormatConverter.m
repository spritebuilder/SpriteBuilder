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
        NSString* dstPath = [[srcPath stringByDeletingLastPathComponent] stringByAppendingPathExtension:@"pvr"];
        if (compress) dstPath = [dstPath stringByAppendingPathExtension:@"ccz"];
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
    
    // Conversion failed
    return NULL;
}

@end
