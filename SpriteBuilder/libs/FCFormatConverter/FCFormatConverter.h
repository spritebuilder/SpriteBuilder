//
//  FCFormatConverter.h
//  CocosBuilder
//
//  Created by Viktor on 6/27/13.
//
//

#import <Foundation/Foundation.h>

enum {
    kFCImageFormatPNG,
    kFCImageFormatPNG_8BIT,
    kFCImageFormatPVR_RGBA8888,
    kFCImageFormatPVR_RGBA4444,
    kFCImageFormatPVR_RGB565,
    kFCImageFormatPVRTC_4BPP,
    kFCImageFormatPVRTC_2BPP,
    kFCImageFormatWEBP,
    kFCImageFormatJPG_High,
    kFCImageFormatJPG_Medium,
    kFCImageFormatJPG_Low,
};

enum {
    kFCSoundFormatCAF,
    kFCSoundFormatMP4,
    kFCSoundFormatOGG,
};

@interface FCFormatConverter : NSObject

+ (FCFormatConverter*) defaultConverter;

- (NSString*) proposedNameForConvertedImageAtPath:(NSString*)srcPath format:(int)format compress:(BOOL)compress isSpriteSheet:(BOOL)isSpriteSheet;

-(BOOL)convertImageAtPath:(NSString*)srcPath
                   format:(int)format
                   dither:(BOOL)dither
                 compress:(BOOL)compress
            isSpriteSheet:(BOOL)isSpriteSheet
           outputFilename:(NSString**)outputFilename
                    error:(NSError**)error;

- (void)cancel;

- (NSString*) proposedNameForConvertedSoundAtPath:(NSString*)srcPath format:(int)format quality:(int)quality;
- (NSString*) convertSoundAtPath:(NSString*)srcPath format:(int)format quality:(int)quality;

@end
