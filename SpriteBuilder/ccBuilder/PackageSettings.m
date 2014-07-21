#import "PackageSettings.h"
#import "RMPackage.h"
#import "CCBPublisherTypes.h"

@interface PackageSettings()

@property (nonatomic, strong) NSMutableDictionary *publishEnabledForOsType;
@property (nonatomic, strong) NSMutableDictionary *publishResolutionsForOsType;

@end


@implementation PackageSettings

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

- (NSArray *)publishResolutionsForOSType:(CCBPublisherOSType)osType
{
    return _publishResolutionsForOsType[@(osType)];
}

- (void)setPublishResolutions:(NSArray *)resolutions forOSType:(CCBPublisherOSType)osType
{
    if (!resolutions)
    {
        return;
    }

    _publishResolutionsForOsType[@(osType)] = resolutions;
}

@end