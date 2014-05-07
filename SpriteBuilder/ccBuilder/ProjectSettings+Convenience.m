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

- (NSArray *)publishingResolutionsForTargetType:(CCBPublisherTargetType)targetType;
{
    if (targetType == kCCBPublisherTargetTypeAndroid)
    {
        return [self publishingResolutionsForAndroid];
    }

    if (targetType == kCCBPublisherTargetTypeIPhone)
    {
        return [self publishingResolutionsForIOS];
    }

    return nil;
}

- (NSArray *)publishingResolutionsForIOS
{
    NSMutableArray *result = [NSMutableArray array];

    if (self.publishResolution_ios_phone)
    {
        [result addObject:@"phone"];
    }
    if (self.publishResolution_ios_phonehd)
    {
        [result addObject:@"phonehd"];
    }
    if (self.publishResolution_ios_tablet)
    {
        [result addObject:@"tablet"];
    }
    if (self.publishResolution_ios_tablethd)
    {
        [result addObject:@"tablethd"];
    }
    return result;
}

- (NSArray *)publishingResolutionsForAndroid
{
    NSMutableArray *result = [NSMutableArray array];

    if (self.publishResolution_android_phone)
    {
        [result addObject:@"phone"];
    }
    if (self.publishResolution_android_phonehd)
    {
        [result addObject:@"phonehd"];
    }
    if (self.publishResolution_android_tablet)
    {
        [result addObject:@"tablet"];
    }
    if (self.publishResolution_android_tablethd)
    {
        [result addObject:@"tablethd"];
    }
    return result;
}

- (NSString *)publishDirForTargetType:(CCBPublisherTargetType)targetType
{
    if (targetType == kCCBPublisherTargetTypeAndroid)
    {
        return [self publishDirectoryAndroid];
    }

    if (targetType == kCCBPublisherTargetTypeIPhone)
    {
        return [self publishDirectory];
    }

    return nil;
}

- (BOOL)publishEnabledForTargetType:(CCBPublisherTargetType)targetType
{
    if (targetType == kCCBPublisherTargetTypeAndroid)
    {
        return self.publishEnabledAndroid;
    }

    if (targetType == kCCBPublisherTargetTypeIPhone)
    {
        return self.publishEnablediPhone;
    }

    return NO;
}


@end