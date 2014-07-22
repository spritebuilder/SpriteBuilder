#import "PackagePublishSettings.h"
#import "RMPackage.h"
#import "CCBPublisherTypes.h"
#import "ResourcePublishPackageCommand.h"
#import "PublishOSSettings.h"

@interface PackagePublishSettings ()

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

- (PublishOSSettings *)settingsForOsType:(CCBPublisherOSType)type;
{
    return _publishSettingsForOsType[[self osTypeToString:type]];
}

- (void)setOSSettings:(PublishOSSettings *)osSettings forOsType:(CCBPublisherOSType)type
{
    if (!osSettings)
    {
        return;
    }

    _publishSettingsForOsType[[self osTypeToString:type]] = osSettings;
}


@end