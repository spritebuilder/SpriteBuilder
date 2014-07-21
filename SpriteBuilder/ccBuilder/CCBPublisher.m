#import "CCBPublisher.h"
#import "ProjectSettings.h"
#import "TaskStatusUpdaterProtocol.h"
#import "DateCache.h"
#import "PublishRenamedFilesLookup.h"
#import "PublishingTaskStatusProgress.h"
#import "OptimizeImageWithOptiPNGOperation.h"
#import "ProjectSettings+Convenience.h"
#import "CCBDirectoryPublisher.h"
#import "PublishGeneratedFilesOperation.h"
#import "CCBPublishingTarget.h"
#import "CCBPublisherCacheCleaner.h"


@interface CCBPublisher ()

@property (nonatomic, copy) PublisherFinishBlock finishBlock;

@property (nonatomic, strong) PublishingTaskStatusProgress *publishingTaskStatusProgress;
@property (nonatomic, strong) NSOperationQueue *publishingQueue;
@property (nonatomic, strong) NSMutableArray *publishingTargets;

// Shared
@property (nonatomic, strong) ProjectSettings *projectSettings;
@property (nonatomic, strong) CCBWarnings *warnings;
@property (nonatomic, strong) NSMutableSet *publishedPNGFiles;
@property (nonatomic, strong) PublishRenamedFilesLookup *renamedFilesLookup;
@property (nonatomic, strong) NSMutableSet *publishedSpriteSheetFiles;
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
    self.publishedPNGFiles = [NSMutableSet set];
    self.publishedSpriteSheetFiles = [[NSMutableSet alloc] init];

    self.publishingTargets = [NSMutableArray array];

    return self;
}

- (void)start
{
    if (_publishingTargets.count == 0)
    {
        NSLog(@"[PUBLISH] Nothing to do: no publishing targets added.");
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

	[self postProcessPublishedPNGFilesWithOptiPNG];

	[_publishingQueue setSuspended:NO];
    [_publishingQueue waitUntilAllOperationsAreFinished];

    [_projectSettings flagFilesDirtyWithWarnings:_warnings];

    #ifndef TESTING
    NSLog(@"[PUBLISH] Done in %.2f seconds.", [[NSDate date] timeIntervalSince1970] - startTime);
    #endif

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
    [self removeOldPublishDirIfCacheCleaned];

    if (![self publishTargets])
    {
        return NO;
    }

    [_projectSettings clearAllDirtyMarkers];

    [self resetNeedRepublish];

    return YES;
}

- (BOOL)publishTargets
{
    for (CCBPublishingTarget *target in _publishingTargets)
    {
        if (![self publishTarget:target])
        {
             return NO;
        }
    }
    return YES;
}

- (BOOL)publishTarget:(CCBPublishingTarget *)target
{
    _warnings.currentOSType = target.osType;

    self.renamedFilesLookup = [[PublishRenamedFilesLookup alloc] initWithFlattenPaths:_projectSettings.flattenPaths];

    for (NSString* aDir in target.inputDirectories)
    {
        CCBDirectoryPublisher *dirPublisher = [[CCBDirectoryPublisher alloc] initWithProjectSettings:_projectSettings
                                                                                            warnings:_warnings
                                                                                               queue:_publishingQueue];
        dirPublisher.inputDir = aDir;
        dirPublisher.outputDir = target.outputDirectory;
        dirPublisher.osType = target.osType;
        dirPublisher.resolutions = target.resolutions;
        dirPublisher.modifiedDatesCache = _modifiedDatesCache;
        dirPublisher.publishedPNGFiles = _publishedPNGFiles;
        dirPublisher.renamedFilesLookup = _renamedFilesLookup;
        dirPublisher.publishedSpriteSheetFiles = _publishedSpriteSheetFiles;
        dirPublisher.publishingTaskStatusProgress = _publishingTaskStatusProgress;

        if (![dirPublisher generateAndEnqueuePublishingTasks])
        {
            return NO;
        }
	}

    if(!_projectSettings.onlyPublishCCBs)
    {
        [self publishGeneratedFilesWithTarget:target];
    }

    // Yiee Haa!
    return YES;
}

- (void)publishGeneratedFilesWithTarget:(CCBPublishingTarget *)target
{
    PublishGeneratedFilesOperation *operation = [[PublishGeneratedFilesOperation alloc] initWithProjectSettings:_projectSettings
                                                                                                       warnings:_warnings
                                                                                                 statusProgress:_publishingTaskStatusProgress];
    operation.osType = target.osType;
    operation.outputDir = target.outputDirectory;
    operation.publishedSpriteSheetFiles = _publishedSpriteSheetFiles;
    operation.fileLookup = _renamedFilesLookup;

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
            NSError *error;
            if (![fileManager removeItemAtPath:target.outputDirectory error:&error])
            {
                NSLog(@"Error removing old publishing directory at path \"%@\" with error %@", target.outputDirectory, error);
            }
        }
    }
}

- (void)postProcessPublishedPNGFilesWithOptiPNG
{
    if ([_projectSettings isPublishEnvironmentDebug])
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

    for (NSString *pngFile in _publishedPNGFiles)
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