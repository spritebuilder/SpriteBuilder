#import "CCBPublisher.h"
#import "ProjectSettings.h"
#import "TaskStatusUpdaterProtocol.h"
#import "DateCache.h"
#import "PublishRenamedFilesLookup.h"
#import "PublishingTaskStatusProgress.h"
#import "OptimizeImageWithOptiPNGOperation.h"
#import "CCBDirectoryPublisher.h"
#import "PublishGeneratedFilesOperation.h"
#import "CCBPublishingTarget.h"
#import "CCBPublisherCacheCleaner.h"
#import "ZipDirectoryOperation.h"
#import "MiscConstants.h"


@interface CCBPublisher ()

@property (nonatomic, copy) PublisherFinishBlock finishBlock;

@property (nonatomic, strong) PublishingTaskStatusProgress *publishingTaskStatusProgress;
@property (nonatomic, strong) NSOperationQueue *publishingQueue;
@property (nonatomic, strong) NSMutableArray *publishingTargets;
@property (nonatomic, strong) ProjectSettings *projectSettings;

// Shared for targets
@property (nonatomic, strong) CCBWarnings *warnings;
@property (nonatomic, strong) DateCache *modifiedDatesCache;

@end


@implementation CCBPublisher

- (id)initWithProjectSettings:(ProjectSettings *)someProjectSettings warnings:(CCBWarnings *)someWarnings finishedBlock:(PublisherFinishBlock)finishBlock;
{
    NSAssert(someProjectSettings != nil, @"project settings should never be nil! Publisher won't work without.");
    NSAssert(someWarnings != nil, @"warnings are nil. Are you sure you don't need them?");

    self = [super init];
	if (!self)
	{
		return NULL;
	}

    self.projectSettings = someProjectSettings;
    self.warnings = someWarnings;
    self.finishBlock = finishBlock;

    self.publishingQueue = [[NSOperationQueue alloc] init];
    _publishingQueue.maxConcurrentOperationCount = 1;

    self.modifiedDatesCache = [[DateCache alloc] init];
    self.publishingTargets = [NSMutableArray array];

    return self;
}

- (void)start
{
    if (_publishingTargets.count == 0)
    {
        NSLog(@"[PUBLISH] Nothing to do: no publishing targets added.");
        [_warnings setCurrentOSType:kCCBPublisherOSTypeNone];
        [_warnings addWarningWithDescription:@"Nothing to publish. Check Project Settings. Common cause: No package is set to publish \"in Main Project\" or \"as Zip file\"" isFatal:YES];
        [self callFinishedBlock];
        return;
    }

    #ifndef TESTING
    NSLog(@"[PUBLISH] Start...");
    #endif

    [_publishingQueue setSuspended:YES];

    NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];

    if (_projectSettings.publishEnvironment == kCCBPublishEnvironmentRelease)
    {
        [CCBPublisherCacheCleaner cleanWithProjectSettings:_projectSettings];
    }

    [self doPublish];

    _publishingTaskStatusProgress.totalTasks = [_publishingQueue operationCount];

    [_publishingQueue setSuspended:NO];
    [_publishingQueue waitUntilAllOperationsAreFinished];

    [self enqueuePostPublishingOperationsForAllTargets];

	[_publishingQueue setSuspended:NO];
    [_publishingQueue waitUntilAllOperationsAreFinished];

    [_projectSettings flagFilesDirtyWithWarnings:_warnings];

    #ifndef TESTING
    NSLog(@"[PUBLISH] Done in %.2f seconds.", [[NSDate date] timeIntervalSince1970] - startTime);
    #endif

    [self callFinishedBlock];
}

- (void)callFinishedBlock
{
    if ([[NSThread currentThread] isMainThread])
    {
        if (_finishBlock)
        {
            _finishBlock(self, _warnings);
        }
    }
    else
    {
        dispatch_sync(dispatch_get_main_queue(), ^
        {
            if (_finishBlock)
            {
                _finishBlock(self, _warnings);
            }
        });
    }
}

- (BOOL)doPublish
{
    __weak id weakSelf = self;
/*    [_publishingQueue addOperationWithBlock:^
    {
        [weakSelf removeOldPublishDirIfCacheCleaned];
    }];*/

    [self removeOldPublishDirIfCacheCleaned];

    if (![self enqueuePublishOperationsForAllTargets])
    {
        return NO;
    }

    [_publishingQueue addOperationWithBlock:^
    {
        [_projectSettings clearAllDirtyMarkers];

        [weakSelf resetNeedRepublish];
    }];

    return YES;
}

- (BOOL)enqueuePublishOperationsForAllTargets
{
    for (CCBPublishingTarget *target in _publishingTargets)
    {
        if (![self enqueuePublishingOperationsForTarget:target])
        {
             return NO;
        }
    }
    return YES;
}

- (BOOL)enqueuePublishingOperationsForTarget:(CCBPublishingTarget *)target
{
    _warnings.currentOSType = target.osType;

    target.renamedFilesLookup = [[PublishRenamedFilesLookup alloc] init];

    for (NSString *aDir in target.inputDirectories)
    {
        CCBDirectoryPublisher *dirPublisher = [[CCBDirectoryPublisher alloc] initWithProjectSettings:_projectSettings
                                                                                            warnings:_warnings
                                                                                               queue:_publishingQueue];
        dirPublisher.inputDir = aDir;
        dirPublisher.outputDir = target.outputDirectory;
        dirPublisher.osType = target.osType;
        dirPublisher.resolutions = target.resolutions;
        dirPublisher.audioQuality = target.audioQuality;
        dirPublisher.publishedPNGFiles = target.publishedPNGFiles;
        dirPublisher.renamedFilesLookup = target.renamedFilesLookup;
        dirPublisher.publishedSpriteSheetFiles = target.publishedSpriteSheetFiles;
        dirPublisher.publishingTaskStatusProgress = _publishingTaskStatusProgress;
        dirPublisher.modifiedDatesCache = _modifiedDatesCache;

        if (![dirPublisher generateAndEnqueuePublishingTasks])
        {
            return NO;
        }
    }

    if (!_projectSettings.onlyPublishCCBs)
    {
        [self enqueueGenerateFilesOperationWithTarget:target];
    }

    // Yiee Haa!
    return YES;
}

- (void)enqueueGenerateFilesOperationWithTarget:(CCBPublishingTarget *)target
{
    PublishGeneratedFilesOperation *operation = [[PublishGeneratedFilesOperation alloc] initWithProjectSettings:_projectSettings
                                                                                                       warnings:_warnings
                                                                                                 statusProgress:_publishingTaskStatusProgress];
    operation.osType = target.osType;
    operation.outputDir = target.outputDirectory;
    operation.publishedSpriteSheetFiles = target.publishedSpriteSheetFiles;
    operation.fileLookup = target.renamedFilesLookup;

    [_publishingQueue addOperation:operation];
}

- (void)resetNeedRepublish
{
    if (_projectSettings.needRepublish)
    {
        _projectSettings.needRepublish = NO;
        [_projectSettings store];
    }
}

- (void)removeOldPublishDirIfCacheCleaned
{
    if (_projectSettings.needRepublish
        && !_projectSettings.onlyPublishCCBs)
    {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        for (CCBPublishingTarget *target in _publishingTargets)
        {
            if (!target.directoryToClean)
            {
                continue;
            }

            NSError *error;
            if (![fileManager removeItemAtPath:target.directoryToClean error:&error]
                && error.code != NSFileNoSuchFileError)
            {
                NSLog(@"Error removing old publishing directory at path \"%@\" with error %@", target.outputDirectory, error);
            }
        }
    }
}

- (void)enqueuePostPublishingOperationsForAllTargets
{
    for (CCBPublishingTarget *target in _publishingTargets)
    {
        [self postProcessPublishedPNGFilesWithOptiPNGWithTarget:target];
        [self zipFolderWithTarget:target];
    }
}

- (void)zipFolderWithTarget:(CCBPublishingTarget *)target
{
    if (!target.zipOutputPath)
    {
        return;
    }

    ZipDirectoryOperation *operation = [[ZipDirectoryOperation alloc] initWithProjectSettings:_projectSettings
                                                                                     warnings:_warnings
                                                                               statusProgress:_publishingTaskStatusProgress];

    operation.inputPath = target.outputDirectory;
    operation.zipOutputPath = target.zipOutputPath;
    operation.compression = target.publishEnvironment == kCCBPublishEnvironmentRelease
        ? PUBLISHING_PACKAGES_ZIP_RELEASE_COMPRESSION
        : PUBLISHING_PACKAGES_ZIP_DEBUG_COMPRESSION;
    operation.createDirectories = YES;

    [_publishingQueue addOperation:operation];
}

- (void)postProcessPublishedPNGFilesWithOptiPNGWithTarget:(CCBPublishingTarget *)target
{
    if (target.publishEnvironment == kCCBPublishEnvironmentDevelop)
    {
        return;
    }

    NSString *pathToOptiPNG = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"optipng"];
    if (!pathToOptiPNG)
    {
        [_warnings addWarningWithDescription:@"Optipng could not be found." isFatal:NO];
        NSLog(@"ERROR: optipng was not found in bundle.");
        return;
    }

    for (NSString *pngFile in target.publishedPNGFiles)
    {
        OptimizeImageWithOptiPNGOperation *operation = [[OptimizeImageWithOptiPNGOperation alloc] initWithProjectSettings:_projectSettings
                                                                                                           warnings:_warnings
                                                                                                     statusProgress:_publishingTaskStatusProgress];
        operation.filePath = pngFile;
        operation.optiPngPath = pathToOptiPNG;

        [_publishingQueue addOperation:operation];
    }
}

- (void)startAsync
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^
    {
        [self start];
    });
}

- (void)cancel
{
    NSLog(@"[PUBLISH] cancelled by user");
    [_publishingQueue cancelAllOperations];
}

- (void)setTaskStatusUpdater:(id <TaskStatusUpdaterProtocol>)taskStatusUpdater
{
    _taskStatusUpdater = taskStatusUpdater;
    self.publishingTaskStatusProgress = [[PublishingTaskStatusProgress alloc] initWithTaskStatus:taskStatusUpdater];
}

- (void)addPublishingTarget:(CCBPublishingTarget *)target
{
    if (!target)
    {
        return;
    }

    [_publishingTargets addObject:target];
}

@end