//
//  FCFormatConverter.h
//  CocosBuilder
//
//  Created by Viktor on 6/27/13.
//
//

#import <Foundation/Foundation.h>

// Please keep explicit value assignments: order is irrelevant and new enum entries can be safely added/removed.
// Persistency is depending on these values.
typedef enum {
    kFCImageFormatPNG = 0,
    kFCImageFormatPNG_8BIT = 1,
    kFCImageFormatPVR_RGBA8888 = 2,
    kFCImageFormatPVR_RGBA4444 = 3,
    kFCImageFormatPVR_RGB565 = 4,
    kFCImageFormatPVRTC_4BPP = 5,
    kFCImageFormatPVRTC_2BPP = 6,
    kFCImageFormatWEBP = 7,
    kFCImageFormatJPG_High = 8,
    kFCImageFormatJPG_Medium = 9,
    kFCImageFormatJPG_Low = 10,
} kFCImageFormat;

typedef enum {
    kFCSoundFormatCAF = 0,
    kFCSoundFormatMP4 = 1,
    kFCSoundFormatOGG = 2,
} kFCSoundFormat;

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
