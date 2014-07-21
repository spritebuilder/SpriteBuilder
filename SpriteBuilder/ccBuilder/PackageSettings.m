#import "PackageSettings.h"
#import "RMPackage.h"

@interface PackageSettings()

@property (nonatomic, strong) NSMutableDictionary *publishEnabledForOsType;

@end


@implementation PackageSettings

- (instancetype)initWithPackage:(RMPackage *)package
{
    self = [super init];

    if (self)
    {
        self.package = package;
        self.publishEnabledForOsType = [NSMutableDictionary dictionary];
    }

    return self;
}

- (BOOL)isPublishEnabledForOSType:(CCBPublisherOSType)osType
{
    return [_publishEnabledForOsType[@(osType)] boolValue];
}

- (void)setPublishEnabled:(BOOL)enabled forOSType:(CCBPublisherOSType)osType
{
    _publishEnabledForOsType[@(osType)] = @(enabled);
}


@end