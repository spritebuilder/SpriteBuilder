#import "ProjectSettings+Convenience.h"
#import "FCFormatConverter.h"
#import "CCBWarnings.h"
#import "NSString+RelativePath.h"
#import "MiscConstants.h"


@implementation ProjectSettings (Convenience)

- (BOOL)isPublishEnvironmentRelease
{
    return self.publishEnvironment == kCCBPublishEnvironmentRelease;
}

- (BOOL)isPublishEnvironmentDebug
{
    return self.publishEnvironment == kCCBPublishEnvironmentDevelop;
}

- (NSInteger)soundQualityForRelPath:(NSString *)relPath osType:(CCBPublisherOSType)osType
{
    NSString *key = osType == kCCBPublisherOSTypeIOS
        ? @"format_ios_sound_quality"
        : @"format_android_sound_quality";

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
        key = @"format_ios_sound";
        map = @{@(0):@(kFCSoundFormatCAF),
                @(1):@(kFCSoundFormatMP4)};
    }
    else if (osType == kCCBPublisherOSTypeAndroid)
    {
        key = @"format_android_sound";
        map = @{@(0):@(kFCSoundFormatOGG)};
    }
    else
    {
        return 0;
    }

    int formatRaw = [[self propertyForRelPath:relPath andKey:key] intValue];

    NSNumber *result = [map objectForKey:@(formatRaw)];

    return result
           ? [result intValue]
           : -1;
}

- (NSArray *)publishingResolutionsForOSType:(CCBPublisherOSType)osType;
{
    if (osType == kCCBPublisherOSTypeAndroid)
    {
        return [self publishingResolutionsForAndroid];
    }

    if (osType == kCCBPublisherOSTypeIOS)
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

- (BOOL)publishEnabledForOSType:(CCBPublisherOSType)osType
{
    if (osType == kCCBPublisherOSTypeAndroid)
    {
        return self.publishEnabledAndroid;
    }

    if (osType == kCCBPublisherOSTypeIOS)
    {
        return self.publishEnabledIOS;
    }

    return NO;
}


- (NSInteger)audioQualityForOsType:(CCBPublisherOSType)osType
{
    if (osType == kCCBPublisherOSTypeAndroid)
    {
        return self.publishAudioQuality_android;
    }

    if (osType == kCCBPublisherOSTypeIOS)
    {
        return self.publishAudioQuality_ios;
    }

    return DEFAULT_AUDIO_QUALITY;
}

@end