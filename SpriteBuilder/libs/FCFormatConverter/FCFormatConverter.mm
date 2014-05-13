//
//  FCFormatConverter.m
//  CocosBuilder
//
//  Created by Viktor on 6/27/13.
//
//

#import "FCFormatConverter.h"
#import "PVRTexture.h"
#import "PVRTextureUtilities.h"

static FCFormatConverter* gDefaultConverter = NULL;

static NSString * kErrorDomain = @"com.apportable.SpriteBuilder";

@interface FCFormatConverter ()

@property (nonatomic, strong) NSTask *pngQuantTask;
@property (nonatomic, strong) NSTask *zipTask;
@property (nonatomic, strong) NSTask *sndTask;

@end

@implementation FCFormatConverter

+ (FCFormatConverter*) defaultConverter
{
    if (!gDefaultConverter)
    {
        gDefaultConverter = [[FCFormatConverter alloc] init];
    }
    return gDefaultConverter;
}

- (NSString*) proposedNameForConvertedImageAtPath:(NSString*)srcPath format:(int)format compress:(BOOL)compress isSpriteSheet:(BOOL)isSpriteSheet
{
    if ( isSpriteSheet )
		{
		    // The name of a sprite in a spritesheet never changes.
		    return [srcPath copy];
		}
    if (format == kFCImageFormatPNG ||
        format == kFCImageFormatPNG_8BIT)
    {
        // File might be loaded from a .psd file.
        return [[srcPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"png"];
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

-(BOOL)convertImageAtPath:(NSString*)srcPath
                   format:(int)format
                   dither:(BOOL)dither
                 compress:(BOOL)compress
            isSpriteSheet:(BOOL)isSpriteSheet
           outputFilename:(NSString**)outputFilename
                    error:(NSError**)error;
{
    NSFileManager* fm = [NSFileManager defaultManager];
    NSString* dstDir = [srcPath stringByDeletingLastPathComponent];
    
    // Convert PSD to PNG as a pre-step.
    // Unless the .psd is part of a spritesheet, then the original name has to be preserved.
    if ( [[srcPath pathExtension] isEqualToString:@"psd"] && !isSpriteSheet)
    {
        CGImageSourceRef image_source = CGImageSourceCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:srcPath], NULL);
        CGImageRef image = CGImageSourceCreateImageAtIndex(image_source, 0, NULL);

        NSString *out_path = [[srcPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"png"];
        CFURLRef out_url = (__bridge CFURLRef)[NSURL fileURLWithPath:out_path];
        CGImageDestinationRef image_destination = CGImageDestinationCreateWithURL(out_url, kUTTypePNG, 1, NULL);
        CGImageDestinationAddImage(image_destination, image, NULL);
        CGImageDestinationFinalize(image_destination);

        CFRelease(image_source);
        CGImageRelease(image);
        CFRelease(image_destination);

        [fm removeItemAtPath:srcPath error:nil];
        srcPath = out_path;
    }
		
    if (format == kFCImageFormatPNG)
    {
        // PNG image - no conversion required
        *outputFilename = [srcPath copy];
        return YES;
    }
    if (format == kFCImageFormatPNG_8BIT)
    {
        // 8 bit PNG image
        self.pngQuantTask = [[NSTask alloc] init];
        [_pngQuantTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"pngquant"]];
        NSMutableArray* args = [NSMutableArray arrayWithObjects:
                                @"--force", @"--ext", @".png", srcPath, nil];
        if (dither) [args addObject:@"-dither"];
        [_pngQuantTask setArguments:args];
        [_pngQuantTask launch];
        [_pngQuantTask waitUntilExit];
        
        self.pngQuantTask = nil;
        if ([fm fileExistsAtPath:srcPath])
        {
            *outputFilename = [srcPath copy];
            return YES;
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
        
        pvrtexture::PixelType pixelType;
        EPVRTVariableType variableType = ePVRTVarTypeUnsignedByteNorm;
        
        if (format == kFCImageFormatPVR_RGBA8888)
        {
            pixelType = pvrtexture::PixelType('r','g','b','a',8,8,8,8);
        }
        else if (format == kFCImageFormatPVR_RGBA4444)
        {
            pixelType = pvrtexture::PixelType('r','g','b','a',4,4,4,4);
            variableType = ePVRTVarTypeUnsignedShortNorm;
        }
        else if (format == kFCImageFormatPVR_RGB565)
        {
            pixelType = pvrtexture::PixelType('r','g','b',0,5,6,5,0);
            variableType = ePVRTVarTypeUnsignedShortNorm;
        }
        else if (format == kFCImageFormatPVRTC_4BPP)
        {
            pixelType = pvrtexture::PixelType(ePVRTPF_PVRTCI_4bpp_RGB);
        }
        else if (format == kFCImageFormatPVRTC_2BPP)
        {
            pixelType = pvrtexture::PixelType(ePVRTPF_PVRTCI_2bpp_RGB);
        }

        NSImage * image = [[NSImage alloc] initWithContentsOfFile:srcPath];
        NSBitmapImageRep* rawImg = [NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]];
        
        pvrtexture::CPVRTextureHeader header(pvrtexture::PVRStandard8PixelType.PixelTypeID, image.size.height , image.size.width);
        pvrtexture::CPVRTexture     * pvrTexture = new pvrtexture::CPVRTexture(header , rawImg.bitmapData);
        
        
        
        bool hasError = NO;
        
        if(!pvrtexture::PreMultiplyAlpha(*pvrTexture))
        {
            if (error)
			{
				NSString * errorMessage = [NSString stringWithFormat:@"Failure to premultiple alpha: %@", srcPath];
				NSDictionary * userInfo __attribute__((unused)) =@{NSLocalizedDescriptionKey:errorMessage};
				*error = [NSError errorWithDomain:kErrorDomain code:EPERM userInfo:userInfo];
			}
            hasError = YES;
        }
        
       
        if(!hasError && !Transcode(*pvrTexture, pixelType, variableType, ePVRTCSpacelRGB, pvrtexture::ePVRTCBest, dither))
        {
            if (error)
            {
                NSString * errorMessage = [NSString stringWithFormat:@"Failure to transcode image: %@", srcPath];
                NSDictionary * userInfo __attribute__((unused)) =@{NSLocalizedDescriptionKey:errorMessage};
                *error = [NSError errorWithDomain:kErrorDomain code:EPERM userInfo:userInfo];
            }
            hasError = YES;
        }
    
        
        if(!hasError)
        {
            CPVRTString filePath([dstPath UTF8String], dstPath.length);
            
            if(!pvrTexture->saveFileLegacyPVR(filePath,  pvrtexture::eOGLES2))
            {
				if (error)
				{
					NSString * errorMessage = [NSString stringWithFormat:@"Failure to save image: %@", dstPath];
					NSDictionary * userInfo __attribute__((unused)) =@{NSLocalizedDescriptionKey:errorMessage};
					*error = [NSError errorWithDomain:kErrorDomain code:EPERM userInfo:userInfo];
				}
                hasError = YES;
            }
        }
        
        // Remove PNG file
        [[NSFileManager defaultManager] removeItemAtPath:srcPath error:NULL];
        //Clean up memory.
        delete pvrTexture;
        
        if(hasError)
        {
            return NO;//return failure;
        }
        
        if (compress)
        {
            // Create compressed file (ccz)
            self.zipTask = [[NSTask alloc] init];
            [_zipTask setCurrentDirectoryPath:dstDir];
            [_zipTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"ccz"]];
            NSMutableArray* args = [NSMutableArray arrayWithObjects:dstPath, nil];
            [_zipTask setArguments:args];
            [_zipTask launch];
            [_zipTask waitUntilExit];
            self.zipTask = nil;

            // Remove uncompressed file
            [[NSFileManager defaultManager] removeItemAtPath:dstPath error:NULL];
            
            // Update name of texture file
            dstPath = [dstPath stringByAppendingPathExtension:@"ccz"];
        }
        
        if ([fm fileExistsAtPath:dstPath])
        {
            *outputFilename = [dstPath copy];
            return YES;
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
        
        *outputFilename = [dstPath copy];
        return YES;
        
    }
    
	// Conversion failed
	if(error != nil)
	{
		*error = [NSError errorWithDomain:kErrorDomain code:EPERM userInfo:@{NSLocalizedDescriptionKey:@"Unhandled format"}];
	}
	
	return NO;
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
        self.sndTask = [[NSTask alloc] init];
        
        [_sndTask setLaunchPath:@"/usr/bin/afconvert"];
        NSMutableArray* args = [NSMutableArray arrayWithObjects:
                                @"-f", @"caff",
                                @"-d", @"LEI16@44100",
                                @"-c", @"1",
                                srcPath, dstPath, nil];
        [_sndTask setArguments:args];
        [_sndTask launch];
        [_sndTask waitUntilExit];

        // Remove old file
        if (![srcPath isEqualToString:dstPath])
        {
            [fm removeItemAtPath:srcPath error:NULL];
        }

        self.sndTask = nil;
        return dstPath;
    }
    else if (format == kFCSoundFormatMP4)
    {
        // Convert to AAC
        
        int qualityScaled = ((quality -1) * 127) / 7;//Quality [1,8]
        
        // Do the conversion
        self.sndTask = [[NSTask alloc] init];
        
        [_sndTask setLaunchPath:@"/usr/bin/afconvert"];
        NSMutableArray* args = [NSMutableArray arrayWithObjects:
                                @"-f", @"m4af",
                                @"-d", @"aac",
                                @"-u", @"pgcm", @"2",
                                @"-u", @"vbrq", [NSString stringWithFormat:@"%i",qualityScaled],
                                @"-q", @"127",
                                @"-s", @"3",
                                srcPath, dstPath, nil];
        [_sndTask setArguments:args];
        [_sndTask launch];
        [_sndTask waitUntilExit];

        // Remove old file
        if (![srcPath isEqualToString:dstPath])
        {
            [fm removeItemAtPath:srcPath error:NULL];
        }

        self.sndTask = nil;
        return dstPath;
    }
    else if (format == kFCSoundFormatOGG)
    {
        // Convert to OGG
        self.sndTask = [[NSTask alloc] init];
        [_sndTask setCurrentDirectoryPath:[srcPath stringByDeletingLastPathComponent]];
        [_sndTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"oggenc"]];
        NSMutableArray* args = [NSMutableArray arrayWithObjects:
                                [NSString stringWithFormat:@"-q%d", quality],
                                @"-o", dstPath, srcPath,
                                nil];
        [_sndTask setArguments:args];
        [_sndTask launch];
        [_sndTask waitUntilExit];

        // Remove old file
        if (![srcPath isEqualToString:dstPath])
        {
            [fm removeItemAtPath:srcPath error:NULL];
        }

        self.sndTask = nil;
        return dstPath;
    }
    
    return NULL;
}

- (void)cancel
{
    @try
    {
        [_pngQuantTask terminate];
        [_zipTask terminate];
        [_sndTask  terminate];

        self.pngQuantTask = nil;
        self.zipTask = nil;
        self.sndTask = nil;
    }
    @catch (NSException *exception)
    {
        NSLog(@"Exception: %@", exception);
    }
}

@end
