#import <MacTypes.h>
#import "CCBPublisherController.h"
#import "ProjectSettings.h"
#import "CCBWarnings.h"
#import "CCBPublishingTarget.h"
#import "ProjectSettings+Convenience.h"
#import "CCBPublisher.h"
#import "RMPackage.h"
#import "SBPackageSettings.h"
#import "PublishOSSettings.h"
#import "NSString+RelativePath.h"
#import "MiscConstants.h"
#import "NSNumber+ImageResolutions.h"

@interface CCBPublisherController()

@property (nonatomic, strong) CCBPublisher *publisher;
@property (nonatomic, strong, readwrite) CCBWarnings *warnings;

@end


@implementation CCBPublisherController

- (void)startAsync:(BOOL)async;
{
    NSAssert(_projectSettings, @"projectSetting must not be nil");

    self.warnings = [[CCBWarnings alloc] init];
    _warnings.warningsDescription = @"Publisher Warnings";

    self.publisher = [[CCBPublisher alloc] initWithProjectSettings:_projectSettings
                                                   packageSettings:_packageSettings
                                                          warnings:_warnings
                                                     finishedBlock:_finishBlock];

    _publisher.taskStatusUpdater = _taskStatusUpdater;

    [self configurePublisher];

    if (async)
    {
        [_publisher startAsync];
    }
    else
    {
        [_publisher start];
    }
}

- (void)configurePublisher
{
    [self addPublishingTargetsForMainProject];

    [self addPublishingTargetsForPackages];
}

- (void)addPublishingTargetsForPackages
{
    for (SBPackageSettings *packageSetting in _packageSettings)
    {
        [self addPublishingTargetsForPackageSetting:packageSetting osType:kCCBPublisherOSTypeIOS];

        [self addPublishingTargetsForPackageSetting:packageSetting osType:kCCBPublisherOSTypeAndroid];
    }
}

- (void)addPublishingTargetsForPackageSetting:(SBPackageSettings *)packageSettings osType:(CCBPublisherOSType)osType
{
    if (!packageSettings.publishToZip)
    {
        return;
    }

    for (NSNumber *resolution in [packageSettings settingsForOsType:osType].resolutions)
    {
        NSString *packagePublishName = [self generatePublishedPackageName:packageSettings.package.name osType:osType resolution:resolution];

        CCBPublishingTarget *target = [[CCBPublishingTarget alloc] init];
        target.osType = osType;
        target.resolutions = @[resolution];
        target.inputPackages = @[packageSettings];
        target.publishEnvironment = packageSettings.publishEnvironment;
        target.zipOutputPath = [self zipOutputPath:packagePublishName baseDir:packageSettings.effectiveOutputDirectory];
        target.outputDirectory = [self cachesPath:packagePublishName];
        target.directoryToClean = [packageSettings.effectiveOutputDirectory absolutePathFromBaseDirPath:_projectSettings.projectPathDir];

        [_publisher addPublishingTarget:target];
    }
}

- (NSString *)generatePublishedPackageName:(NSString *)packageName osType:(CCBPublisherOSType)osType resolution:(NSNumber *)resolution
{
    return [[NSString stringWithFormat:@"%@-%@", packageName, [self osTypeToString:osType]] stringByAppendingString:[resolution resolutionTag]];
}

- (NSString *)zipOutputPath:(NSString *)PublishedPackageName baseDir:(NSString *)baseDir
{
    NSString *result = [self createOutputDirectoryWithPackageName:PublishedPackageName
                                                          baseDir:baseDir
                                                       createDirs:NO];

    return [result stringByAppendingPathExtension:@"zip"];
}

- (NSString *)cachesPath:(NSString *)PublishedPackageName
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachesPath = [[paths[0] stringByAppendingPathComponent:PUBLISHER_CACHE_DIRECTORY_NAME] stringByAppendingPathComponent:@"packages"];

    NSString *result = [self createOutputDirectoryWithPackageName:PublishedPackageName
                                                          baseDir:cachesPath
                                                       createDirs:NO];

    return result;
}

- (NSString *)createOutputDirectoryWithPackageName:(NSString *)publishedPackageName
                                           baseDir:(NSString *)baseDir
                                        createDirs:(BOOL)createDirs
{
    NSString *fullPathToOutputDir = [baseDir absolutePathFromBaseDirPath:_projectSettings.projectPathDir];
    NSString *fullPath = [fullPathToOutputDir stringByAppendingPathComponent:publishedPackageName];

    if (createDirs)
    {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error;
        if (![fileManager createDirectoryAtPath:fullPath withIntermediateDirectories:YES attributes:nil error:&error])
        {
            NSLog(@"Error creating package output dir \"%@\" with error %@", fullPath, error);
            return nil;
        }
    }

    return fullPath;
}

- (NSString *)osTypeToString:(CCBPublisherOSType)osType
{
    switch (osType)
    {
        case
            kCCBPublisherOSTypeIOS : return @"iOS";
        case
            kCCBPublisherOSTypeAndroid : return @"Android";
        default:
            return @"";
    }
}

- (void)addPublishingTargetsForMainProject
{
    if (_projectSettings.publishEnabledIOS)
    {
        [self addMainProjectPublishingTargetToPublisherForOSType:kCCBPublisherOSTypeIOS];
    }

    if (_projectSettings.publishEnabledAndroid)
    {
        [self addMainProjectPublishingTargetToPublisherForOSType:kCCBPublisherOSTypeAndroid];
    }
}

- (void)addMainProjectPublishingTargetToPublisherForOSType:(CCBPublisherOSType)osType
{
    NSMutableArray *inputPackages = [[self inputDirsOfPackagePublishSettingsEnabledForMainProject] mutableCopy];

    if ([inputPackages count] == 0)
    {
        return;
    }

    CCBPublishingTarget *target = [[CCBPublishingTarget alloc] init];
    target.inputPackages = inputPackages;
    target.osType = osType;
    target.outputDirectory = [_projectSettings publishDirForOSType:osType];
    target.useMainProjectResolutionsOfInputPackages = YES;
    target.resolutions = nil;
    target.publishEnvironment = _projectSettings.publishEnvironment;
    target.directoryToClean = [_projectSettings publishDirForOSType:osType];

    [_publisher addPublishingTarget:target];
}

- (NSArray *)inputDirsOfPackagePublishSettingsEnabledForMainProject
{
    NSMutableArray *inputDirs = [NSMutableArray array];
    for (SBPackageSettings *somePackageSettings in _packageSettings)
    {
        if (somePackageSettings.publishToMainProject)
        {
            [inputDirs addObject:somePackageSettings];
        }
    }
    return inputDirs;
}

- (void)cancel
{
    [_publisher cancel];
}

@end