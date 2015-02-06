#import "ProjectSettings+Convenience.h"
#import "FCFormatConverter.h"
#import "CCBWarnings.h"
#import "NSString+RelativePath.h"
#import "MiscConstants.h"
#import "ResourcePropertyKeys.h"


@implementation ProjectSettings (Convenience)

- (NSInteger)soundQualityForRelPath:(NSString *)relPath osType:(CCBPublisherOSType)osType
{
    NSString *key = osType == kCCBPublisherOSTypeIOS
        ? RESOURCE_PROPERTY_IOS_SOUND_QUALITY
        : RESOURCE_PROPERTY_ANDROID_SOUND_QUALITY;

    int result = [[self propertyForRelPath:relPath andKey:key] intValue];
    if (!result)
    {
        return NSNotFound;
    }
    return result;
}

- (int)soundFormatForRelPath:(NSString *)relPath osType:(CCBPublisherOSType)osType
{
    NSString *key;
    NSDictionary *map;
    if (osType == kCCBPublisherOSTypeIOS)
    {
        key = RESOURCE_PROPERTY_IOS_SOUND;
        map = @{@(0):@(kFCSoundFormatCAF),
                @(1):@(kFCSoundFormatMP4)};
    }
    else if (osType == kCCBPublisherOSTypeAndroid)
    {
        key = RESOURCE_PROPERTY_ANDROID_SOUND;
        map = @{@(0):@(kFCSoundFormatOGG)};
    }
    else
    {
        return 0;
    }

    int formatRaw = [[self propertyForRelPath:relPath andKey:key] intValue];

    NSNumber *result = map[@(formatRaw)];

    return result
           ? [result intValue]
           : -1;
}

- (NSString *)publishDirForOSType:(CCBPublisherOSType)osType
{
    NSString *result;
    if (osType == kCCBPublisherOSTypeAndroid)
    {
        result = [self publishDirectoryAndroid];
    }

    if (osType == kCCBPublisherOSTypeIOS)
    {
        result = [self publishDirectory];
    }

    if (!result)
    {
        NSLog(@"Error: unknown target type: %d", osType);
        return nil;
    }

    return [result absolutePathFromBaseDirPath:[self.projectPath stringByDeletingLastPathComponent]];
}

@end
