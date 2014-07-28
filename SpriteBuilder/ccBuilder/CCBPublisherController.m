#import <MacTypes.h>
#import "CCBPublisherController.h"
#import "ProjectSettings.h"
#import "CCBWarnings.h"
#import "CCBPublishingTarget.h"
#import "ProjectSettings+Convenience.h"
#import "CCBPublisher.h"
#import "RMPackage.h"
#import "PackagePublishSettings.h"
#import "PublishOSSettings.h"
#import "NSString+RelativePath.h"
#import "MiscConstants.h"

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
    for (PackagePublishSettings *packageSetting in _packageSettings)
    {
        [self addPublishingTargetsForPackageSetting:packageSetting osType:kCCBPublisherOSTypeIOS];

        #ifdef SPRITEBUILDER_PRO
        [self addPublishingTargetsForPackageSetting:packageSetting osType:kCCBPublisherOSTypeAndroid];
        #endif
    }
}

- (void)addPublishingTargetsForPackageSetting:(PackagePublishSettings *)packageSettings osType:(CCBPublisherOSType)osType
{
    if (!packageSettings.publishToZip)
    {
        return;
    }

    for (NSString *resolution in [packageSettings settingsForOsType:osType].resolutions)
    {
        NSString *packagePublishName = [self generatePublishedPackageName:packageSettings.package.name osType:osType resolution:resolution];

        CCBPublishingTarget *target = [[CCBPublishingTarget alloc] init];
        target.osType = osType;
        target.resolutions = @[resolution];
        target.inputDirectories = @[packageSettings.package.fullPath];
        target.publishEnvironment = packageSettings.publishEnvironment;
        target.audioQuality = [packageSettings settingsForOsType:osType].audio_quality;
        target.zipOutputPath = [self zipOutputPath:packagePublishName baseDir:packageSettings.effectiveOutputDirectory];
        target.outputDirectory = [self cachesPath:packagePublishName];
        target.directoryToClean = [packageSettings.effectiveOutputDirectory absolutePathFromBaseDirPath:_projectSettings.projectPathDir];

        [_publisher addPublishingTarget:target];
    }
}

- (NSString *)generatePublishedPackageName:(NSString *)packageName osType:(CCBPublisherOSType)osType resolution:(NSString *)resolution
{
    return [NSString stringWithFormat:@"%@-%@-%@", packageName, [self osTypeToString:osType], resolution];
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
    NSString *cachesPath = [[[paths objectAtIndex:0] stringByAppendingPathComponent:PUBLISHER_CACHE_DIRECTORY_NAME] stringByAppendingPathComponent:@"packages"];

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

    #ifdef SPRITEBUILDER_PRO
    if (_projectSettings.publishEnabledAndroid)
    {
        [self addMainProjectPublishingTargetToPublisherForOSType:kCCBPublisherOSTypeAndroid];
    }
    #endif
}

- (void)addMainProjectPublishingTargetToPublisherForOSType:(CCBPublisherOSType)osType
{
    NSMutableArray *inputDirs = [[self inputDirsOfPackagePublishSettingsEnabledForMainProject] mutableCopy];
    [inputDirs addObjectsFromArray:[self inputDirsOfResourcePaths]];

    if ([inputDirs count] == 0)
    {
        return;
    }

    CCBPublishingTarget *target = [[CCBPublishingTarget alloc] init];
    target.osType = osType;
    target.outputDirectory = [_projectSettings publishDirForOSType:osType];
    target.resolutions = [_projectSettings publishingResolutionsForOSType:osType];
    target.inputDirectories = inputDirs;
    target.publishEnvironment = _projectSettings.publishEnvironment;
    target.audioQuality = [_projectSettings audioQualityForOsType:osType];
    target.directoryToClean = [_projectSettings publishDirForOSType:osType];

    [_publisher addPublishingTarget:target];
}

- (NSArray *)inputDirsOfResourcePaths
{
    NSMutableArray *result = [NSMutableArray array];
    for (RMDirectory *oldResourcePath in _oldResourcePaths)
    {
        [result addObject:oldResourcePath.dirPath];
    }
    return result;

}

- (NSArray *)inputDirsOfPackagePublishSettingsEnabledForMainProject
{
    NSMutableArray *inputDirs = [NSMutableArray array];
    for (PackagePublishSettings *somePackageSettings in _packageSettings)
    {
        if (!somePackageSettings.publishToMainProject)
        {
            continue;
        }
        [inputDirs addObject:somePackageSettings.package.dirPath];
    }
    return inputDirs;
}

- (void)cancel
{
    [_publisher cancel];
}

@end