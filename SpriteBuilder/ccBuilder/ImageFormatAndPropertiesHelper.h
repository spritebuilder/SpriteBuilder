#import <Foundation/Foundation.h>
#import "CCBPublisherTypes.h"
#import "FCFormatConverter.h"

@interface ImageFormatAndPropertiesHelper : NSObject

// Returns if a given value is a power of two
+ (BOOL)isValueAPowerOfTwo:(NSInteger)value;

// Returns if a given format for an os supports compress used in FCFormatConverter
+ (BOOL)supportsCompress:(kFCImageFormat)format osType:(CCBPublisherOSType)osType;

// Returns if a given format for an os supports dither used in FCFormatConverter
+ (BOOL)supportsDither:(kFCImageFormat)format osType:(CCBPublisherOSType)osType;

@end