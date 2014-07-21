#import "ProjectSettings+Convenience.h"
#import "FCFormatConverter.h"
#import "CCBWarnings.h"
#import "NSString+RelativePath.h"


@implementation ProjectSettings (Convenience)

- (BOOL)isPublishEnvironmentRelease
{
    return self.publishEnvironment == PublishEnvironmentRelease;
}

- (BOOL)isPublishEnvironmentDebug
{
    return self.publishEnvironment == PublishEnvironmentDevelop;
}

- (int)soundQualityForRelPath:(NSString *)relPath targetType:(CCBPublisherOSType)targetType
{
    NSString *key = targetType == kCCBPublisherOSTypeIOS
        ? @"format_ios_sound_quality"
        : @"format_android_sound_quality";

    int result = [[self valueForRelPath:relPath andKey:key] intValue];
    if (!result)
    {
        return self.publishAudioQuality_ios;
    }
    return result;
}

- (int)soundFormatForRelPath:(NSString *)relPath targetType:(CCBPublisherOSType)targetType
{
    NSString *key;
    NSDictionary *map;
    if (targetType == kCCBPublisherOSTypeIOS)
    {
        key = @"format_ios_sound";
        map = @{@(0):@(kFCSoundFormatCAF),
                @(1):@(kFCSoundFormatMP4)};
    }
    else if (targetType == kCCBPublisherOSTypeAndroid)
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

- (NSArray *)publishingResolutionsForTargetType:(CCBPublisherOSType)targetType;
{
    if (targetType == kCCBPublisherOSTypeAndroid)
    {
        return [self publishingResolutionsForAndroid];
    }

    if (targetType == kCCBPublisherOSTypeIOS)
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

- (NSString *)publishDirForTargetType:(CCBPublisherOSType)targetType
{
    NSString *result;
    if (targetType == kCCBPublisherOSTypeAndroid)
    {
        result = [self publishDirectoryAndroid];
    }

    if (targetType == kCCBPublisherOSTypeIOS)
    {
        result = [self publishDirectory];
    }

    if (!result)
    {
        NSLog(@"Error: unknown target type: %d", targetType);
        return nil;
    }

    return [result absolutePathFromBaseDirPath:[self.projectPath stringByDeletingLastPathComponent]];
}

- (BOOL)publishEnabledForTargetType:(CCBPublisherOSType)targetType
{
    if (targetType == kCCBPublisherOSTypeAndroid)
    {
        return self.publishEnabledAndroid;
    }

    if (targetType == kCCBPublisherOSTypeIOS)
    {
        return self.publishEnablediPhone;
    }

    return NO;
}


@end