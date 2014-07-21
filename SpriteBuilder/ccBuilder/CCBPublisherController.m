#import <MacTypes.h>
#import "CCBPublisherController.h"
#import "ProjectSettings.h"
#import "CCBWarnings.h"
#import "CCBPublishingTarget.h"
#import "ProjectSettings+Convenience.h"
#import "CCBPublisher.h"
#import "RMPackage.h"
#import "PackageSettings.h"

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
    for (PackageSettings *packageSetting in _packageSettings)
    {
        [self addPublishingTargetsForPackageSetting:packageSetting osType:(kCCBPublisherOSTypeIOS)];
        [self addPublishingTargetsForPackageSetting:packageSetting osType:(kCCBPublisherOSTypeAndroid)];
    }
}

- (void)addPublishingTargetsForPackageSetting:(PackageSettings *)packageSettings osType:(CCBPublisherOSType)osType
{
    if (![packageSettings isPublishEnabledForOSType:osType])
    {
        return;
    }

    for (NSString *resolution in [packageSettings publishResolutionsForOSType:osType])
    {
        CCBPublishingTarget *target = [[CCBPublishingTarget alloc] init];
        target.osType = osType;
        target.resolutions = @[resolution];
        target.inputDirectories = @[packageSettings.package.fullPath];
        target.publishEnvironment = packageSettings.publishEnvironment;
        target.zipOutputFolder = YES;

        NSError *error;
        NSString *outputDirectory = [self createOutputDirectoryForPackageWithPackageSetting:packageSettings
                                                                                     osType:osType
                                                                                 resolution:resolution
                                                                                      error:&error];
        if (!outputDirectory)
        {
            NSString *warning = [NSString stringWithFormat:@"Package export failed: Could not create directory at \"%@\", error: %@",
                                          outputDirectory,
                                          error.localizedDescription];

            [_warnings addWarningWithDescription:warning];
            continue;
        }

        target.outputDirectory = outputDirectory;

        [_publisher addPublishingTarget:target];
    }
}

- (NSString *)createOutputDirectoryForPackageWithPackageSetting:(PackageSettings *)settings
                                                         osType:(CCBPublisherOSType)osType
                                                     resolution:(NSString *)resolution
                                                          error:(NSError **)error
{
    NSString *packageDirName = [NSString stringWithFormat:@"%@-%@-%@", settings.package.name, [self osTypeToString:osType], resolution];
    NSString *fullPath = [settings.outputDirectory stringByAppendingPathComponent:packageDirName];


    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager createDirectoryAtPath:fullPath withIntermediateDirectories:YES attributes:nil error:error])
    {
        NSLog(@"Error creating package output dir \"%@\" with error %@", fullPath, *error);
        return nil;
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
    if (_projectSettings.publishEnablediPhone)
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
    CCBPublishingTarget *target = [[CCBPublishingTarget alloc] init];
    target.osType = osType;
    target.outputDirectory = [_projectSettings publishDirForOSType:osType];
    target.resolutions = [_projectSettings publishingResolutionsForOSType:osType];
    target.inputDirectories = _projectSettings.absoluteResourcePaths;
    target.publishEnvironment = _projectSettings.publishEnvironment;

    [_publisher addPublishingTarget:target];
}

- (void)cancel
{
    [_publisher cancel];
}

@end