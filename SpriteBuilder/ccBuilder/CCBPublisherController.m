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

- (void)addPublishingTargetsForPackageSetting:(PackageSettings *)packageSetting osType:(CCBPublisherOSType)osType
{
    if (![packageSetting isPublishEnabledForOSType:osType])
    {
        return;
    }

    for (NSString *resolution in packageSetting.resolutions)
    {
        CCBPublishingTarget *target = [[CCBPublishingTarget alloc] init];
        target.osType = osType;
        target.outputDirectory = packageSetting.outputDirectory;
        target.resolutions = @[resolution];
        target.inputDirectories = @[packageSetting.package.fullPath];
        target.publishEnvironment = packageSetting.publishEnvironment;

        [_publisher addPublishingTarget:target];
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