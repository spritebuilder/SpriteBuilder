#import <MacTypes.h>
#import "PackagePublishSettings.h"
#import "RMPackage.h"
#import "CCBPublisherTypes.h"
#import "PublishOSSettings.h"
#import "MiscConstants.h"

NSString *const KEY_PUBLISH_TO_CUSTOM_DIRECTORY = @"publishToCustomDirectory";
NSString *const KEY_PUBLISH_TO_ZIP = @"publishToZip";
NSString *const KEY_PUBLISH_TO_MAINPROJECT = @"publishToMainProject";
NSString *const KEY_OS_SETTINGS = @"osSettings";
NSString *const KEY_OUTPUTDIR = @"outputDir";
NSString *const KEY_PUBLISH_ENV = @"publishEnv";

@interface PackagePublishSettings ()

@property (nonatomic, strong) NSMutableDictionary *publishSettingsForOsType;

@end


@implementation PackagePublishSettings

- (instancetype)init
{
    NSLog(@"Error initializing PackagePublishSettings, use initWithPackage:");
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (instancetype)initWithPackage:(RMPackage *)package
{
    self = [super init];

    if (self)
    {
        self.publishToZip = NO;
        self.publishToMainProject = YES;
        self.publishToCustomOutputDirectory = NO;

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
        case kCCBPublisherOSTypeIOS :
            return @"ios";

        case kCCBPublisherOSTypeAndroid :
            return @"android";

        default :
            return nil;
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

- (BOOL)load
{
    NSString *fullPath = [_package.dirPath stringByAppendingPathComponent:@"Package.plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:fullPath];

    if (!dict)
    {
        return NO;
    }

    self.publishToCustomOutputDirectory = [dict[KEY_PUBLISH_TO_CUSTOM_DIRECTORY] boolValue];
    self.publishToZip = [dict[KEY_PUBLISH_TO_ZIP] boolValue];
    self.publishToMainProject = [dict[KEY_PUBLISH_TO_MAINPROJECT] boolValue];
    self.customOutputDirectory = dict[KEY_OUTPUTDIR];
    self.publishEnvironment = (CCBPublishEnvironment) [dict[KEY_PUBLISH_ENV] integerValue];

    for (NSString *osType in dict[KEY_OS_SETTINGS])
    {
        NSDictionary *dictOsSettings = dict[KEY_OS_SETTINGS][osType];
        PublishOSSettings *publishOSSettings = [[PublishOSSettings alloc] initWithDictionary:dictOsSettings];
        _publishSettingsForOsType[osType] = publishOSSettings;
    }

    return YES;
}

- (BOOL)store
{
    NSAssert(_package != nil, @"package must not be nil");

    NSDictionary *dict = [self toDictionary];
    NSString *fullPath = [_package.dirPath stringByAppendingPathComponent:PACKAGE_PUBLISH_SETTINGS_FILE_NAME];
    return [dict writeToFile:fullPath atomically:YES];
}

- (NSDictionary *)toDictionary
{
    NSMutableDictionary *result = [NSMutableDictionary dictionary];

    result[KEY_PUBLISH_TO_CUSTOM_DIRECTORY] = @(_publishToCustomOutputDirectory);
    result[KEY_PUBLISH_TO_ZIP] = @(_publishToZip);
    result[KEY_PUBLISH_TO_MAINPROJECT] = @(_publishToMainProject);
    result[KEY_PUBLISH_ENV] = @(_publishEnvironment);
    result[KEY_OUTPUTDIR] = _customOutputDirectory
        ? _customOutputDirectory
        : @"";

    result[KEY_OS_SETTINGS] = [NSMutableDictionary dictionary];

    for (NSString *osType in _publishSettingsForOsType)
    {
        PublishOSSettings *someOsSettings = _publishSettingsForOsType[osType];

        result[KEY_OS_SETTINGS][osType] = [someOsSettings toDictionary];
    }

    return result;
}

- (NSString *)effectiveOutputDirectory
{
    return _publishToCustomOutputDirectory
        ? _customOutputDirectory
        : DEFAULT_OUTPUTDIR_PUBLISHED_PACKAGES;
}

@end