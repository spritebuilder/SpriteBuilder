#import "ProjectSettings+Convenience.h"
#import "FCFormatConverter.h"
#import "CCBWarnings.h"


@implementation ProjectSettings (Convenience)

- (BOOL)isPublishEnvironmentRelease
{
    return self.publishEnvironment == PublishEnvironmentRelease;
}

- (BOOL)isPublishEnvironmentDebug
{
    return self.publishEnvironment == PublishEnvironmentDevelop;
}

- (int)soundQualityForRelPath:(NSString *)relPath targetType:(CCBPublisherTargetType)targetType
{
    NSString *key = targetType == kCCBPublisherTargetTypeIPhone
        ? @"format_ios_sound_quality"
        : @"format_android_sound_quality";

    int result = [[self valueForRelPath:relPath andKey:key] intValue];
    if (!result)
    {
        return self.publishAudioQuality_ios;
    }
    return result;
}

- (int)soundFormatForRelPath:(NSString *)relPath targetType:(CCBPublisherTargetType)targetType
{
    NSString *key;
    NSDictionary *map;
    if (targetType == kCCBPublisherTargetTypeIPhone)
    {
        key = @"format_ios_sound";
        map = @{@(0):@(kFCSoundFormatCAF),
                @(1):@(kFCSoundFormatMP4)};
    }
    else if (targetType == kCCBPublisherTargetTypeAndroid)
    {
        key = @"format_android_sound";
        map = @{@(0):@(kFCSoundFormatOGG)};
    }
    else
    {
        return 0;
    }

    int formatRaw = [[self valueForRelPath:relPath andKey:key] intValue];

    NSNumber *result = [map objectForKey:@(formatRaw)];

    return result
           ? [result intValue]
           : -1;
}

@end