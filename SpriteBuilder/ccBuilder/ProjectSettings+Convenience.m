#import "ProjectSettings+Convenience.h"
#import "FCFormatConverter.h"
#import "CCBWarnings.h"
#import "NSString+RelativePath.h"
#import "MiscConstants.h"
#import "ResourcePropertyKeys.h"


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
        [result addObject:RESOLUTION_PHONE];
    }
    if (self.publishResolution_ios_phonehd)
    {
        [result addObject:RESOLUTION_PHONE_HD];
    }
    if (self.publishResolution_ios_tablet)
    {
        [result addObject:RESOLUTION_TABLET];
    }
    if (self.publishResolution_ios_tablethd)
    {
        [result addObject:RESOLUTION_TABLET_HD];
    }
    return result;
}

- (NSArray *)publishingResolutionsForAndroid
{
    NSMutableArray *result = [NSMutableArray array];

    if (self.publishResolution_android_phone)
    {
        [result addObject:RESOLUTION_PHONE];
    }
    if (self.publishResolution_android_phonehd)
    {
        [result addObject:RESOLUTION_PHONE_HD];
    }
    if (self.publishResolution_android_tablet)
    {
        [result addObject:RESOLUTION_TABLET];
    }
    if (self.publishResolution_android_tablethd)
    {
        [result addObject:RESOLUTION_TABLET_HD];
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