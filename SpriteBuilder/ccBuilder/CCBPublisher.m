/*
 * CocosBuilder: http://www.cocosbuilder.com
 *
 * Copyright (c) 2012 Zynga Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "CCBPublisher.h"
#import "ProjectSettings.h"
#import "CCBWarnings.h"
#import "NSString+RelativePath.h"
#import "PlugInManager.h"
#import "CCBGlobals.h"
#import "AppDelegate.h"
#import "ResourceManager.h"
#import "CCBFileUtil.h"
#import "ResourceManagerUtil.h"
#import "OptimizeImageWithOptiPNGOperation.h"
#import "PublishSpriteSheetOperation.h"
#import "PublishRegularFileOperation.h"
#import "TaskStatusUpdaterProtocol.h"
#import "PublishSoundFileOperation.h"
#import "ProjectSettings+Convenience.h"
#import "PublishCCBOperation.h"
#import "PublishImageOperation.h"
#import "DateCache.h"
#import "NSString+Publishing.h"
#import "PublishGeneratedFilesOperation.h"
#import "PublishRenamedFilesLookup.h"
#import "PublishSpriteKitSpriteSheetOperation.h"
#import "PublishingTaskStatusProgress.h"
#import "PublishLogging.h"

@interface CCBPublisher ()

@property (nonatomic, strong) PublishingTaskStatusProgress *publishingTaskStatusProgress;
@property (nonatomic, strong) PublishRenamedFilesLookup *renamedFilesLookup;
@property (nonatomic, strong) NSArray *publishForResolutions;
@property (nonatomic, strong) NSArray *supportedFileExtensions;
@property (nonatomic, strong) ProjectSettings *projectSettings;
@property (nonatomic, strong) CCBWarnings *warnings;
@property (nonatomic, copy) NSString *outputDir;
@property (nonatomic, strong) DateCache *modifiedDatesCache;
@property (nonatomic, strong) NSOperationQueue *publishingQueue;
@property (nonatomic) CCBPublisherTargetType targetType;
@property (nonatomic, strong) NSMutableSet *publishedPNGFiles;
@property (nonatomic, strong) NSMutableSet *publishedSpriteSheetFiles;

@end


@implementation CCBPublisher

- (id)initWithProjectSettings:(ProjectSettings *)someProjectSettings warnings:(CCBWarnings *)someWarnings
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

    self.modifiedDatesCache = [[DateCache alloc] init];

    self.publishingQueue = [[NSOperationQueue alloc] init];
    _publishingQueue.maxConcurrentOperationCount = 1;

    self.supportedFileExtensions = @[@"jpg", @"png", @"psd", @"pvr", @"ccz", @"plist", @"fnt", @"ttf",@"js", @"json", @"wav",@"mp3",@"m4a",@"caf",@"ccblang"];

    self.publishedPNGFiles = [NSMutableSet set];
    self.publishedSpriteSheetFiles = [[NSMutableSet alloc] init];

    return self;
}

- (BOOL)publishImageForResolutions:(NSString *)srcFile to:(NSString *)dstFile isSpriteSheet:(BOOL)isSpriteSheet outDir:(NSString *)outDir
{
    for (NSString* resolution in _publishForResolutions)
    {
        [self publishImageFile:srcFile to:dstFile isSpriteSheet:isSpriteSheet outputDir:outDir resolution:resolution];
	}

    return YES;
}

- (BOOL)publishImageFile:(NSString *)srcFilePath
                      to:(NSString *)dstFilePath
           isSpriteSheet:(BOOL)isSpriteSheet
               outputDir:(NSString *)outputDir
              resolution:(NSString *)resolution
{
    PublishImageOperation *operation = [[PublishImageOperation alloc] initWithProjectSettings:_projectSettings
                                                                                     warnings:_warnings
                                                                               statusProgress:_publishingTaskStatusProgress];

    operation.srcFilePath = srcFilePath;
    operation.dstFilePath = dstFilePath;
    operation.isSpriteSheet = isSpriteSheet;
    operation.outputDir = outputDir;
    operation.resolution = resolution;
    operation.targetType = _targetType;
    operation.modifiedFileDateCache = _modifiedDatesCache;
    operation.publishedPNGFiles = _publishedPNGFiles;
    operation.fileLookup = _renamedFilesLookup;

    [_publishingQueue addOperation:operation];
    return YES;
}

- (void)publishSoundFile:(NSString *)srcFilePath to:(NSString *)dstFilePath
{
    NSString *relPath = [ResourceManagerUtil relativePathFromAbsolutePath:srcFilePath];

    int format = [_projectSettings soundFormatForRelPath:relPath targetType:_targetType];
    int quality = [_projectSettings soundQualityForRelPath:relPath targetType:_targetType];
    if (format == -1)
    {
        [_warnings addWarningWithDescription:[NSString stringWithFormat:@"Invalid sound conversion format for %@", relPath] isFatal:YES];
        return;
    }

    PublishSoundFileOperation *operation = [[PublishSoundFileOperation alloc] initWithProjectSettings:_projectSettings
                                                                                             warnings:_warnings
                                                                                       statusProgress:_publishingTaskStatusProgress];
    operation.srcFilePath = srcFilePath;
    operation.dstFilePath = dstFilePath;
    operation.format = format;
    operation.quality = quality;
    operation.fileLookup = _renamedFilesLookup;

    [_publishingQueue addOperation:operation];
}

- (void)publishRegularFile:(NSString *)srcFilePath to:(NSString*)dstFilePath
{
    PublishRegularFileOperation *operation = [[PublishRegularFileOperation alloc] initWithProjectSettings:_projectSettings
                                                                                                 warnings:_warnings
                                                                                           statusProgress:_publishingTaskStatusProgress];
    operation.srcFilePath = srcFilePath;
    operation.dstFilePath = dstFilePath;

    [_publishingQueue addOperation:operation];
}

- (BOOL)publishDirectory:(NSString *)publishDirectory subPath:(NSString *)subPath
{
	NSString *outDir = [self outputDirectory:subPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];

    BOOL isGeneratedSpriteSheet = [[_projectSettings valueForRelPath:subPath andKey:@"isSmartSpriteSheet"] boolValue];
    if (!isGeneratedSpriteSheet)
	{
        BOOL createdDirs = [fileManager createDirectoryAtPath:outDir withIntermediateDirectories:YES attributes:NULL error:NULL];
        if (!createdDirs)
        {
            [_warnings addWarningWithDescription:@"Failed to create output directory %@" isFatal:YES];
            return NO;
        }
	}

    if (![self processAllFilesWithinPublishDir:publishDirectory
                                       subPath:subPath
                                     outputDir:outDir
                        isGeneratedSpriteSheet:isGeneratedSpriteSheet])
    {
        return NO;
    }

    if (isGeneratedSpriteSheet)
    {
        [self publishSpriteSheetDir:publishDirectory subPath:subPath outputDir:outDir];
    }
    
    return YES;
}

- (void)publishSpriteSheetDir:(NSString *)publishDirectory subPath:(NSString *)subPath outputDir:(NSString *)outputDir
{
    BOOL publishForSpriteKit = _projectSettings.engine == CCBTargetEngineSpriteKit;
    if (publishForSpriteKit)
    {
        [self publishSpriteKitAtlasDir:[outputDir stringByDeletingLastPathComponent]
                             sheetName:[outputDir lastPathComponent]
                               subPath:subPath
                            publishDir:publishDirectory
                             outputDir:outputDir];
    }
    else
    {
        // Sprite files should have been saved to the temp cache directory, now actually generate the sprite sheets
        [self publishSpriteSheetDir:[outputDir stringByDeletingLastPathComponent]
                          sheetName:[outputDir lastPathComponent]
                   publishDirectory:publishDirectory
                            subPath:subPath
                          outputDir:outputDir];
    }
}

- (BOOL)processAllFilesWithinPublishDir:(NSString *)publishDirectory
                                subPath:(NSString *)subPath
                              outputDir:(NSString *)outputDir
                 isGeneratedSpriteSheet:(BOOL)isGeneratedSpriteSheet
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray* resIndependentDirs = [ResourceManager resIndependentDirs];

    NSMutableSet* files = [NSMutableSet setWithArray:[fileManager contentsOfDirectoryAtPath:publishDirectory error:NULL]];
	[files addObjectsFromArray:[publishDirectory resolutionDependantFilesInDirWithResolutions:_publishForResolutions]];
    [files addObjectsFromArray:[publishDirectory filesInAutoDirectory]];

    for (NSString* fileName in files)
    {
		if ([fileName hasPrefix:@"."])
		{
			continue;
		}

		NSString* filePath = [publishDirectory stringByAppendingPathComponent:fileName];

        BOOL isDirectory;
        BOOL fileExists = [fileManager fileExistsAtPath:filePath isDirectory:&isDirectory];

        if (fileExists && isDirectory)
        {
            [self processDirectory:fileName
                           subPath:subPath
                           dirPath:filePath
                resIndependentDirs:resIndependentDirs
                         outputDir:outputDir
            isGeneratedSpriteSheet:isGeneratedSpriteSheet];
        }
        else
        {
            BOOL success = [self processFile:fileName
                                     subPath:subPath
                                    filePath:filePath
                                   outputDir:outputDir
                      isGeneratedSpriteSheet:isGeneratedSpriteSheet];
            if (!success)
            {
                return NO;
            }
        }
    }
    return YES;
}

- (BOOL)processFile:(NSString *)fileName
            subPath:(NSString *)subPath
           filePath:(NSString *)filePath
          outputDir:(NSString *)outputDir isGeneratedSpriteSheet:(BOOL)isGeneratedSpriteSheet
{
    // Skip non png files for generated sprite sheets
    if (isGeneratedSpriteSheet
        && ![fileName isSmartSpriteSheetCompatibleFile])
    {
        [_warnings addWarningWithDescription:[NSString stringWithFormat:@"Non-png|psd file in smart sprite sheet found (%@)", [fileName lastPathComponent]] isFatal:NO relatedFile:subPath];
        return YES;
    }

    if ([self isFileSupportedByPublishing:fileName]
        && !_projectSettings.onlyPublishCCBs)
    {
        NSString *dstFilePath = [outputDir stringByAppendingPathComponent:fileName];

        if (!isGeneratedSpriteSheet
            && ([fileName isSmartSpriteSheetCompatibleFile]))
        {
            [self publishImageForResolutions:filePath to:dstFilePath isSpriteSheet:isGeneratedSpriteSheet outDir:outputDir];
        }
        else if ([fileName isWaveSoundFile])
        {
            [self publishSoundFile:filePath to:dstFilePath];
        }
        else
        {
            [self publishRegularFile:filePath to:dstFilePath];
        }
    }
    else if (!isGeneratedSpriteSheet
             && [[fileName lowercaseString] hasSuffix:@"ccb"])
    {
        [self publishCCB:fileName filePath:filePath outputDir:outputDir];
    }
    return YES;
}

- (BOOL)isFileSupportedByPublishing:(NSString *)fileName
{
    NSString *extension = [[fileName pathExtension] lowercaseString];

    return [_supportedFileExtensions containsObject:extension];
}

- (void)processDirectory:(NSString *)directoryName
                 subPath:(NSString *)subPath
                 dirPath:(NSString *)dirPath
      resIndependentDirs:(NSArray *)resIndependentDirs
               outputDir:(NSString *)outputDir
  isGeneratedSpriteSheet:(BOOL)isGeneratedSpriteSheet
{
    NSFileManager *fileManager = [NSFileManager defaultManager];

    if ([[dirPath pathExtension] isEqualToString:@"bmfont"])
    {
        [self publishBMFont:directoryName dirPath:dirPath outputDir:outputDir];
        return;
    }

    // Skip resource independent directories
    if ([resIndependentDirs containsObject:directoryName])
    {
        return;
    }

    // Skip directories in generated sprite sheets
    if (isGeneratedSpriteSheet)
    {
        [_warnings addWarningWithDescription:[NSString stringWithFormat:@"Generated sprite sheets do not support directories (%@)", [directoryName lastPathComponent]] isFatal:NO relatedFile:subPath];
        return;
    }

    // Skip the empty folder
    if ([[fileManager contentsOfDirectoryAtPath:dirPath error:NULL] count] == 0)
    {
        return;
    }

    // Skip the fold no .ccb files when onlyPublishCCBs is true
    if (_projectSettings.onlyPublishCCBs
        && ![dirPath containsCCBFile])
    {
        return;
    }

    // This is a directory
    NSString *childPath = subPath
        ? [NSString stringWithFormat:@"%@/%@", subPath, directoryName]
        : directoryName;

    [self publishDirectory:dirPath subPath:childPath];
}

- (void)publishCCB:(NSString *)fileName filePath:(NSString *)filePath outputDir:(NSString *)outputDir
{
    NSString *dstFile = [[outputDir stringByAppendingPathComponent:[fileName stringByDeletingPathExtension]]
                                 stringByAppendingPathExtension:_projectSettings.exporter];

    PublishCCBOperation *operation = [[PublishCCBOperation alloc] initWithProjectSettings:_projectSettings
                                                                                 warnings:_warnings
                                                                           statusProgress:_publishingTaskStatusProgress];
    operation.fileName = fileName;
    operation.filePath = filePath;
    operation.dstFilePath = dstFile;

    [_publishingQueue addOperation:operation];
}


- (void)publishBMFont:(NSString *)directoryName dirPath:(NSString *)dirPath outputDir:(NSString *)outputDir
{
    NSString *bmFontOutDir = [outputDir stringByAppendingPathComponent:directoryName];
    [self publishRegularFile:dirPath to:bmFontOutDir];

    // Run after regular file has been copied, else png files cannot be found
    [_publishingQueue addOperationWithBlock:^
    {
        [_publishedPNGFiles addObjectsFromArray:[bmFontOutDir allPNGFilesInPath]];
    }];

    return;
}

- (NSString *)outputDirectory:(NSString *)subPath
{
	NSString *outDir;
	if (_projectSettings.flattenPaths
        && _projectSettings.publishToZipFile)
    {
        outDir = _outputDir;
    }
    else
    {
        outDir = [_outputDir stringByAppendingPathComponent:subPath];
    }
	return outDir;
}

- (void)publishSpriteSheetDir:(NSString *)spriteSheetDir
                    sheetName:(NSString *)spriteSheetName
             publishDirectory:(NSString *)publishDirectory
                      subPath:(NSString *)subPath
                    outputDir:(NSString *)outputDir
{
    // NOTE: For every spritesheet one shared dir is used, so have to remove it on the
    // queue to ensure that later spritesheets don't add more sprites from previous passes
    [_publishingQueue addOperationWithBlock:^
    {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager removeItemAtPath:[_projectSettings tempSpriteSheetCacheDirectory] error:NULL];
    }];

    NSDate *srcSpriteSheetDate = [publishDirectory latestModifiedDateOfPath];

	[_publishedSpriteSheetFiles addObject:[subPath stringByAppendingPathExtension:@"plist"]];

    [PublishSpriteSheetOperation resetSpriteSheetPreviewsGeneration];

	for (NSString *resolution in _publishForResolutions)
	{
		NSString *spriteSheetFile = [[spriteSheetDir stringByAppendingPathComponent:[NSString stringWithFormat:@"resources-%@", resolution]] stringByAppendingPathComponent:spriteSheetName];

		if ([self spriteSheetExistsAndUpToDate:srcSpriteSheetDate spriteSheetFile:spriteSheetFile subPath:subPath])
		{
            LocalLog(@"[SPRITESHEET] SKIPPING exists and up to date - file name: %@, subpath: %@, resolution: %@, file path: %@", [spriteSheetFile lastPathComponent], subPath, resolution, spriteSheetFile);
			continue;
		}

        [self prepareImagesForSpriteSheetPublishing:publishDirectory outputDir:outputDir resolution:resolution];

        PublishSpriteSheetOperation *operation = [[PublishSpriteSheetOperation alloc] initWithProjectSettings:_projectSettings
                                                                                                     warnings:_warnings
                                                                                               statusProgress:_publishingTaskStatusProgress];
        operation.publishDirectory = publishDirectory;
        operation.publishedPNGFiles = _publishedPNGFiles;
        operation.srcSpriteSheetDate = srcSpriteSheetDate;
        operation.resolution = resolution;
        operation.srcDirs = @[[_projectSettings.tempSpriteSheetCacheDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"resources-%@", resolution]],
                              _projectSettings.tempSpriteSheetCacheDirectory];
        operation.spriteSheetFile = spriteSheetFile;
        operation.subPath = subPath;
        operation.targetType = _targetType;

        [_publishingQueue addOperation:operation];
	}
}

- (BOOL)spriteSheetExistsAndUpToDate:(NSDate *)srcSpriteSheetDate spriteSheetFile:(NSString *)spriteSheetFile subPath:(NSString *)subPath
{
    NSDate* dstDate = [CCBFileUtil modificationDateForFile:[spriteSheetFile stringByAppendingPathExtension:@"plist"]];
    BOOL isDirty = [_projectSettings isDirtyRelPath:subPath];
    return dstDate
            && [dstDate isEqualToDate:srcSpriteSheetDate]
            && !isDirty;
}

- (void)prepareImagesForSpriteSheetPublishing:(NSString *)publishDirectory outputDir:(NSString *)outputDir resolution:(NSString *)resolution
{
    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSMutableSet *files = [NSMutableSet setWithArray:[fileManager contentsOfDirectoryAtPath:publishDirectory error:NULL]];
	[files addObjectsFromArray:[publishDirectory resolutionDependantFilesInDirWithResolutions:nil]];
    [files addObjectsFromArray:[publishDirectory filesInAutoDirectory]];

    for (NSString *fileName in files)
    {
        NSString *filePath = [publishDirectory stringByAppendingPathComponent:fileName];

        if ([filePath isResourceAutoFile]
            && ([fileName isSmartSpriteSheetCompatibleFile]))
        {
            NSString *dstFile = [[_projectSettings tempSpriteSheetCacheDirectory] stringByAppendingPathComponent:fileName];
            [self publishImageFile:filePath
                                to:dstFile
                     isSpriteSheet:NO
                         outputDir:outputDir
                        resolution:resolution];
        }
    }
}

- (void)publishSpriteKitAtlasDir:(NSString *)spriteSheetDir
                       sheetName:(NSString *)spriteSheetName
                         subPath:(NSString *)subPath
                      publishDir:(NSString *)publishDir
                       outputDir:(NSString *)outputDir
{
    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSString *textureAtlasPath = [[NSBundle mainBundle] pathForResource:@"SpriteKitTextureAtlasToolPath" ofType:@"txt"];
    NSAssert(textureAtlasPath, @"Missing bundle file: SpriteKitTextureAtlasToolPath.txt");
    NSString *textureAtlasToolLocation = [NSString stringWithContentsOfFile:textureAtlasPath encoding:NSUTF8StringEncoding error:nil];
    LocalLog(@"Using Sprite Kit Texture Atlas tool: %@", textureAtlasToolLocation);

    if ([fileManager fileExistsAtPath:textureAtlasToolLocation] == NO)
    {
        [_warnings addWarningWithDescription:@"<-- file not found! Install a public (non-beta) Xcode version to generate sprite sheets. Xcode beta users may edit 'SpriteKitTextureAtlasToolPath.txt' inside SpriteBuilder.app bundle." isFatal:YES relatedFile:textureAtlasToolLocation];
        return;
    }
	
	for (NSString* resolution in _publishForResolutions)
	{
        [self prepareImagesForSpriteSheetPublishing:publishDir outputDir:outputDir resolution:resolution];

        PublishSpriteKitSpriteSheetOperation *operation = [[PublishSpriteKitSpriteSheetOperation alloc] initWithProjectSettings:_projectSettings
                                                                                                     warnings:_warnings
                                                                                               statusProgress:_publishingTaskStatusProgress];
        operation.resolution = resolution;
        operation.spriteSheetDir = spriteSheetDir;
        operation.spriteSheetName = spriteSheetName;
        operation.subPath = subPath;
        operation.textureAtlasToolFilePath = textureAtlasToolLocation;

        [_publishingQueue addOperation:operation];
    }
}

- (void)publishGeneratedFiles
{
    PublishGeneratedFilesOperation *operation = [[PublishGeneratedFilesOperation alloc] initWithProjectSettings:_projectSettings
                                                                                                       warnings:_warnings
                                                                                                 statusProgress:_publishingTaskStatusProgress];
    operation.targetType = _targetType;
    operation.outputDir = _outputDir;
    operation.publishedSpriteSheetFiles = _publishedSpriteSheetFiles;
    operation.fileLookup = _renamedFilesLookup;

    [_publishingQueue addOperation:operation];
}

- (BOOL)publishAllToDirectory:(NSString*)outputDir
{
    self.outputDir = outputDir;
    self.renamedFilesLookup = [[PublishRenamedFilesLookup alloc] initWithFlattenPaths:_projectSettings.flattenPaths];

    // Publish resources and ccb-files
    for (NSString* aDir in _projectSettings.absoluteResourcePaths)
    {
		if (![self publishDirectory:aDir subPath:NULL])
		{
			return NO;
		}
	}

    if(!_projectSettings.onlyPublishCCBs)
    {
        [self publishGeneratedFiles];
    }
    
    // Yiee Haa!
    return YES;
}

- (BOOL)doPublish
{
    [self removeOldPublishDirIfCacheCleaned];

    if (![self publishForTargetType:kCCBPublisherTargetTypeIPhone])
    {
        return NO;
    }

/*
    if (![self publishForTargetType:kCCBPublisherTargetTypeAndroid])
    {
        return NO;
    }
*/

    [_projectSettings clearAllDirtyMarkers];

    [self resetNeedRepublish];

    return YES;
}

- (BOOL)publishForTargetType:(CCBPublisherTargetType)targetType
{
    BOOL publishEnabled = [_projectSettings publishEnabledForTargetType:targetType];
    if (!publishEnabled)
    {
        return YES;
    }

    _targetType = targetType;
    _warnings.currentTargetType = targetType;

    self.publishForResolutions = [self.projectSettings publishingResolutionsForTargetType:targetType];

    NSString *publishDir = [[_projectSettings publishDirForTargetType:targetType]
                                              absolutePathFromBaseDirPath:[_projectSettings.projectPath stringByDeletingLastPathComponent]];

    return [self publishAllToDirectory:publishDir];
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
        NSArray *publishDirs = @[_projectSettings.publishDirectory, _projectSettings.publishDirectoryAndroid];
        for (NSString * dir in publishDirs)
        {
            NSString *publishDir = [dir absolutePathFromBaseDirPath:[_projectSettings.projectPath stringByDeletingLastPathComponent]];
            [fileManager removeItemAtPath:publishDir error:NULL];
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


#pragma mark - public methods

- (void)start
{
    NSLog(@"[PUBLISH] Start...");

    [_publishingQueue setSuspended:YES];

    NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];

    if (_projectSettings.publishEnvironment == PublishEnvironmentRelease)
    {
        [CCBPublisher cleanAllCacheDirectoriesWithProjectSettings:_projectSettings];
    }

    [self doPublish];

    _publishingTaskStatusProgress.totalTasks = [_publishingQueue operationCount];

    [_publishingQueue setSuspended:NO];
    [_publishingQueue waitUntilAllOperationsAreFinished];
	
	[self postProcessPublishedPNGFilesWithOptiPNG];

	[_publishingQueue setSuspended:NO];
    [_publishingQueue waitUntilAllOperationsAreFinished];
	
    [_projectSettings flagFilesDirtyWithWarnings:_warnings];

    NSLog(@"[PUBLISH] Done in %.2f seconds.", [[NSDate date] timeIntervalSince1970] - startTime);

    if ([[NSThread currentThread] isMainThread])
    {
        [[AppDelegate appDelegate] publisher:self finishedWithWarnings:_warnings];
    }
    else
    {
        dispatch_sync(dispatch_get_main_queue(), ^
        {
            [[AppDelegate appDelegate] publisher:self finishedWithWarnings:_warnings];
        });
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

+ (void)cleanAllCacheDirectoriesWithProjectSettings:(ProjectSettings *)projectSettings
{
    projectSettings.needRepublish = YES;
    [projectSettings store];

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString* ccbChacheDir = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"com.cocosbuilder.CocosBuilder"];
    [[NSFileManager defaultManager] removeItemAtPath:ccbChacheDir error:NULL];
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

@end