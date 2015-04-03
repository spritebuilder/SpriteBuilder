#import "PackageSettings.h"
#import "RMPackage.h"
#import "PublishOSSettings.h"
#import "MiscConstants.h"
#import "PublishResolutions.h"
#import "PackageSettingsMigrator.h"
#import "NSError+SBErrors.h"
#import "Errors.h"


NSString *const KEY_VERSION = @"version";
NSString *const KEY_PUBLISH_TO_CUSTOM_DIRECTORY = @"publishToCustomDirectory";
NSString *const KEY_PUBLISH_TO_ZIP = @"publishToZip";
NSString *const KEY_PUBLISH_TO_MAINPROJECT = @"publishToMainProject";
NSString *const KEY_OS_SETTINGS = @"osSettings";
NSString *const KEY_OUTPUTDIR = @"outputDir";
NSString *const KEY_PUBLISH_ENV = @"publishEnv";
NSString *const KEY_DEFAULT_SCALE = @"resourceAutoScaleFactor";
NSString *const KEY_MAINPROJECT_RESOLUTIONS = @"mainProjectResolutions";

NSUInteger const PACKAGE_SETTINGS_VERSION = 3;

// It's a tag for a dropdown
NSInteger const DEFAULT_TAG_VALUE_GLOBAL_DEFAULT_SCALING = 4;

@interface PackageSettings ()

@property (nonatomic, strong) NSMutableDictionary *publishSettingsForOsType;
@property (nonatomic, strong, readwrite) PublishResolutions *mainProjectResolutions;

@end


@implementation PackageSettings

- (instancetype)init
{
    NSLog(@"Error initializing SBPackageSettings, use initWithPackage:");
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (instancetype)initWithPackage:(RMPackage *)package
{
    self = [super init];

    if (self)
    {
        self.mainProjectResolutions = [[PublishResolutions alloc] init];

        self.publishToZip = NO;
        self.publishToMainProject = YES;
        self.publishToCustomOutputDirectory = NO;
        self.resourceAutoScaleFactor = DEFAULT_TAG_VALUE_GLOBAL_DEFAULT_SCALING;

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

- (BOOL)loadWithError:(NSError **)error
{
    NSString *fullPath = [_package.dirPath stringByAppendingPathComponent:@"Package.plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:fullPath];

    if (!dict || [dict count] == 0)
    {
        [NSError setNewErrorWithErrorPointer:error code:SBPackageSettingsEmptyOrDoesNotExist message:@"Package.plist file is empty or does not exist."];
        return NO;
    }

    self.mainProjectResolutions = [[PublishResolutions alloc] initWithData:dict[KEY_MAINPROJECT_RESOLUTIONS]];
    self.publishToCustomOutputDirectory = [dict[KEY_PUBLISH_TO_CUSTOM_DIRECTORY] boolValue];
    self.publishToZip = [dict[KEY_PUBLISH_TO_ZIP] boolValue];
    self.publishToMainProject = [dict[KEY_PUBLISH_TO_MAINPROJECT] boolValue];
    self.customOutputDirectory = dict[KEY_OUTPUTDIR];
    self.publishEnvironment = (CCBPublishEnvironment) [dict[KEY_PUBLISH_ENV] integerValue];
    self.resourceAutoScaleFactor = [dict[KEY_DEFAULT_SCALE] integerValue];

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
    return [dict writeToFile:self.fullPath atomically:YES ];
}

- (NSString *)fullPath
{
    return [_package.dirPath stringByAppendingPathComponent:PACKAGE_PUBLISH_SETTINGS_FILE_NAME];
}

- (NSDictionary *)toDictionary
{
    NSMutableDictionary *result = [NSMutableDictionary dictionary];

    result[KEY_VERSION] = @(PACKAGE_SETTINGS_VERSION);
    result[KEY_MAINPROJECT_RESOLUTIONS] = [_mainProjectResolutions serialize];
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

    result[KEY_DEFAULT_SCALE] = @(_resourceAutoScaleFactor);

    return result;
}

- (NSString *)effectiveOutputDirectory
{
    return _publishToCustomOutputDirectory
           && ([[_customOutputDirectory stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] > 0)
        ? _customOutputDirectory
        : DEFAULT_OUTPUTDIR_PUBLISHED_PACKAGES;
}

@end
