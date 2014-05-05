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
    int result = [[self valueForRelPath:relPath andKey:@"format_ios_sound_quality"] intValue];
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
        NSLog(@"ERROR: Android target type not supported at the moment, please refer to the git history.");
        return 0;
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