#import "ImageFormatAndPropertiesHelper.h"

@implementation ImageFormatAndPropertiesHelper

+ (BOOL)isValueAPowerOfTwo:(NSInteger)value
{
    double result = log((double) value)/log(2.0);

    return 1 << (int)result == value;
}

+ (BOOL)supportsCompress:(kFCImageFormat)format osType:(CCBPublisherOSType)osType
{
    NSArray *formatsSupportingComress;

    if (osType ==  kCCBPublisherOSTypeIOS)
    {
        formatsSupportingComress = @[
                @(kFCImageFormatPVR_RGBA8888),
                @(kFCImageFormatPVR_RGBA4444),
                @(kFCImageFormatPVR_RGB565),
                @(kFCImageFormatPVRTC_2BPP),
                @(kFCImageFormatPVRTC_4BPP)
        ];
    }

    if (osType ==  kCCBPublisherOSTypeAndroid)
    {
        formatsSupportingComress = @[];
    }

    return [formatsSupportingComress containsObject:@(format)];
}


@end