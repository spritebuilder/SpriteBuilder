#import <MacTypes.h>
#import "PackagePublishSettings.h"
#import "RMPackage.h"
#import "CCBPublisherTypes.h"
#import "ResourcePublishPackageCommand.h"
#import "PublishOSSettings.h"

@interface PackagePublishSettings ()

@property (nonatomic, strong) NSMutableDictionary *publishEnabledForOsType;
@property (nonatomic, strong) NSMutableDictionary *publishResolutionsForOsType;
@property (nonatomic, strong) NSMutableDictionary *publishSettingsForOsType;

@end


@implementation PackagePublishSettings

- (instancetype)init
{
    return [self initWithPackage:nil];
}

- (instancetype)initWithPackage:(RMPackage *)package
{
    self = [super init];

    if (self)
    {
        self.package = package;
        self.publishEnabledForOsType = [NSMutableDictionary dictionary];
        self.publishResolutionsForOsType = [NSMutableDictionary dictionary];
        self.publishSettingsForOsType = [NSMutableDictionary dictionary];

        _publishSettingsForOsType[[self osTypeToString:kCCBPublisherOSTypeIOS]] = [[PublishOSSettings alloc] init];
        _publishSettingsForOsType[[self osTypeToString:kCCBPublisherOSTypeAndroid]] = [[PublishOSSettings alloc] init];
    }

    return self;
}

- (NSString *)osTypeToString:(CCBPublisherOSType)osType
{
    switch (osType)
    {
        case kCCBPublisherOSTypeIOS : return @"ios";
        case kCCBPublisherOSTypeAndroid : return @"android";
        default : return nil;
    }
}

- (NSDictionary *)osSettings
{
    return _publishSettingsForOsType;
}

- (BOOL)isPublishEnabledForOSType:(CCBPublisherOSType)osType
{
    return [_publishEnabledForOsType[@(osType)] boolValue];
}

- (void)setPublishEnabled:(BOOL)enabled forOSType:(CCBPublisherOSType)osType
{
    _publishEnabledForOsType[@(osType)] = @(enabled);
}

- (NSArray *)publishResolutionsForOSType:(CCBPublisherOSType)osType
{
   PublishOSSettings *publishOSSettings = [self settingsForOsType:osType];
   return publishOSSettings.resolutions;
}

- (void)setPublishResolutions:(NSArray *)resolutions forOSType:(CCBPublisherOSType)osType
{
    if (!resolutions)
    {
        return;
    }

    _publishResolutionsForOsType[@(osType)] = resolutions;
}

- (PublishOSSettings *)settingsForOsType:(CCBPublisherOSType)type;
{
    return _publishSettingsForOsType[[self osTypeToString:type]];
}

@end