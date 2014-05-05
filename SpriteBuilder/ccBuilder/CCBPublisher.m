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
#import "PublishSoundFileOperation.h"
#import "ProjectSettings+Convenience.h"
#import "PublishCCBOperation.h"
#import "PublishImageOperation.h"
#import "DateCache.h"
#import "NSString+Publishing.h"
#import "PublishGeneratedFilesOperation.h"
#import "PublishFileLookup.h"
#import "PublishSpriteKitSpriteSheetOperation.h"

@interface CCBPublisher ()

@property (nonatomic) NSUInteger operationsFinished;
@property (nonatomic) NSUInteger totalProgressUnits;
@property (nonatomic, strong) PublishFileLookup *fileLookup;
@property (nonatomic, strong) NSArray *publishForResolutions;
@property (nonatomic, strong) NSArray *supportedFileExtensions;
@property (nonatomic, strong) ProjectSettings *projectSettings;
@property (nonatomic, strong) CCBWarnings *warnings;
@property (nonatomic, copy) NSString *outputDir;
@property (nonatomic, strong) NSMutableSet *publishedResources;
@property (nonatomic, strong) NSMutableArray *publishedSpriteSheetNames;
@property (nonatomic, strong) NSMutableSet *publishedSpriteSheetFiles;
@property (nonatomic, strong) DateCache *modifiedDatesCache;
@property (nonatomic, strong) NSMutableSet *publishedPNGFiles;
@property (nonatomic, strong) NSOperationQueue *publishingQueue;
@property (nonatomic) CCBPublisherTargetType targetType;

@end


@implementation CCBPublisher


- (id)initWithProjectSettings:(ProjectSettings *)someProjectSettings warnings:(CCBWarnings *)someWarnings
{
    self = [super init];
	if (!self)
	{
		return NULL;
	}

    self.modifiedDatesCache = [[DateCache alloc] init];

    self.publishedPNGFiles = [NSMutableSet set];

    self.publishingQueue = [[NSOperationQueue alloc] init];
    _publishingQueue.maxConcurrentOperationCount = 1;

    self.projectSettings = someProjectSettings;
    self.warnings = someWarnings;

    self.supportedFileExtensions = @[@"jpg", @"png", @"psd", @"pvr", @"ccz", @"plist", @"fnt", @"ttf",@"js", @"json", @"wav",@"mp3",@"m4a",@"caf",@"ccblang"];
    
    self.publishedSpriteSheetNames = [[NSMutableArray alloc] init];
    self.publishedSpriteSheetFiles = [[NSMutableSet alloc] init];

    return self;
}

- (BOOL)publishImageForResolutions:(NSString *)srcFile to:(NSString *)dstFile isSpriteSheet:(BOOL)isSpriteSheet outDir:(NSString *)outDir
{
    for (NSString* resolution in _publishForResolutions)
    {
        [self publishImageFile:srcFile to:dstFile isSpriteSheet:isSpriteSheet outDir:outDir resolution:resolution];
	}

    return YES;
}

- (BOOL)publishImageFile:(NSString *)srcPath to:(NSString *)dstPath isSpriteSheet:(BOOL)isSpriteSheet outDir:(NSString *)outDir resolution:(NSString *)resolution
{
    PublishImageOperation *operation = [[PublishImageOperation alloc] initWithProjectSettings:_projectSettings
                                                                                     warnings:_warnings
                                                                                    publisher:self];
    operation.srcPath = srcPath;
    operation.dstPath = dstPath;
    operation.isSpriteSheet = isSpriteSheet;
    operation.outDir = outDir;
    operation.resolution = resolution;
    operation.targetType = _targetType;
    operation.publishedResources = _publishedResources;
    operation.modifiedFileDateCache = _modifiedDatesCache;
    operation.publisher = self;
    operation.publishedPNGFiles = _publishedPNGFiles;
    operation.fileLookup = _fileLookup;

    [_publishingQueue addOperation:operation];
    return YES;
}

- (void)publishSoundFile:(NSString *)srcPath to:(NSString *)dstPath
{
    NSString *relPath = [ResourceManagerUtil relativePathFromAbsolutePath:srcPath];

    int format = [_projectSettings soundFormatForRelPath:relPath targetType:_targetType];
    int quality = [_projectSettings soundQualityForRelPath:relPath targetType:_targetType];
    if (format == -1)
    {
        [_warnings addWarningWithDescription:[NSString stringWithFormat:@"Invalid sound conversion format for %@", relPath] isFatal:YES];
        return;
    }

    PublishSoundFileOperation *operation = [[PublishSoundFileOperation alloc] initWithProjectSettings:_projectSettings
                                                                                             warnings:_warnings
                                                                                            publisher:self];
    operation.srcFilePath = srcPath;
    operation.dstFilePath = dstPath;
    operation.format = format;
    operation.quality = quality;
    operation.fileLookup = _fileLookup;

    [_publishingQueue addOperation:operation];
}

- (void)publishRegularFile:(NSString *)srcPath to:(NSString*) dstPath
{
    PublishRegularFileOperation *operation = [[PublishRegularFileOperation alloc] initWithProjectSettings:_projectSettings
                                                                                                 warnings:_warnings
                                                                                                publisher:self];

    operation.srcFilePath = srcPath;
    operation.dstFilePath = dstPath;

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
                                        outDir:outDir
                        isGeneratedSpriteSheet:isGeneratedSpriteSheet])
    {
        return NO;
    }

    if (isGeneratedSpriteSheet)
    {
        [self publishSpriteSheetDir:publishDirectory subPath:subPath outDir:outDir];
    }
    
    return YES;
}

- (void)publishSpriteSheetDir:(NSString *)publishDirectory subPath:(NSString *)subPath outDir:(NSString *)outDir
{
    BOOL publishForSpriteKit = _projectSettings.engine == CCBTargetEngineSpriteKit;
    if (publishForSpriteKit)
    {
        [self publishSpriteKitAtlasDir:[outDir stringByDeletingLastPathComponent]
                             sheetName:[outDir lastPathComponent]
                               subPath:subPath];
    }
    else
    {
        // Sprite files should have been saved to the temp cache directory, now actually generate the sprite sheets
        [self publishSpriteSheetDir:[outDir stringByDeletingLastPathComponent]
                          sheetName:[outDir lastPathComponent]
                   publishDirectory:publishDirectory
                            subPath:subPath
                             outDir:outDir];
    }
}

- (BOOL)processAllFilesWithinPublishDir:(NSString *)publishDirectory
                                subPath:(NSString *)subPath
                                 outDir:(NSString *)outDir
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
                            outDir:outDir
            isGeneratedSpriteSheet:isGeneratedSpriteSheet];
        }
        else
        {
            BOOL success = [self processFile:fileName
                                     subPath:subPath
                                    filePath:filePath
                                      outDir:outDir
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
             outDir:(NSString *)outDir
        isGeneratedSpriteSheet:(BOOL)isGeneratedSpriteSheet
{
    // Skip non png files for generated sprite sheets
    if (isGeneratedSpriteSheet
        && ![fileName isSmartSpriteSheetCompatibleFile])
    {
        [_warnings addWarningWithDescription:[NSString stringWithFormat:@"Non-png|psd file in smart sprite sheet (%@)", [fileName lastPathComponent]] isFatal:NO relatedFile:subPath];
        return YES;
    }

    if ([self isFileSupportedByPublishing:fileName]
        && !_projectSettings.onlyPublishCCBs)
    {
        NSString *dstFilePath = [outDir stringByAppendingPathComponent:fileName];

        if (!isGeneratedSpriteSheet
            && ([fileName isSmartSpriteSheetCompatibleFile]))
        {
            [self publishImageForResolutions:filePath to:dstFilePath isSpriteSheet:isGeneratedSpriteSheet outDir:outDir];
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
        [self publishCCB:fileName filePath:filePath outDir:outDir];
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
                  outDir:(NSString *)outDir
  isGeneratedSpriteSheet:(BOOL)isGeneratedSpriteSheet
{
    NSFileManager *fileManager = [NSFileManager defaultManager];

    if ([[dirPath pathExtension] isEqualToString:@"bmfont"])
    {
        [self publishBMFont:directoryName dirPath:dirPath outDir:outDir];
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

- (void)publishCCB:(NSString *)fileName filePath:(NSString *)filePath outDir:(NSString *)outDir
{
    NSString *dstFile = [[outDir stringByAppendingPathComponent:[fileName stringByDeletingPathExtension]]
                                 stringByAppendingPathExtension:_projectSettings.exporter];

    // Add file to list of published files
    NSString *localFileName = [dstFile relativePathFromBaseDirPath:_outputDir];
    // TODO: move to base class or to a delegate
    [_publishedResources addObject:localFileName];

    PublishCCBOperation *operation = [[PublishCCBOperation alloc] initWithProjectSettings:_projectSettings
                                                                                 warnings:_warnings
                                                                                publisher:self];
    operation.fileName = fileName;
    operation.filePath = filePath;
    operation.dstFile = dstFile;
    operation.outDir = outDir;

    [_publishingQueue addOperation:operation];
}


- (void)publishBMFont:(NSString *)directoryName dirPath:(NSString *)dirPath outDir:(NSString *)outDir
{
    NSString *bmFontOutDir = [outDir stringByAppendingPathComponent:directoryName];
    [self publishRegularFile:dirPath to:bmFontOutDir];

    // Run after regular file has been copied, else png files cannot be found
    [_publishingQueue addOperationWithBlock:^
    {
        // TODO: this can be generalized
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
                       outDir:(NSString *)outDir
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

	for (NSString *resolution in _publishForResolutions)
	{
		NSString *spriteSheetFile = [[spriteSheetDir stringByAppendingPathComponent:[NSString stringWithFormat:@"resources-%@", resolution]] stringByAppendingPathComponent:spriteSheetName];

		if ([self spriteSheetExistsAndUpToDate:srcSpriteSheetDate spriteSheetFile:spriteSheetFile subPath:subPath])
		{
			continue;
		}

        [self prepareImagesForSpriteSheetPublishing:publishDirectory outDir:outDir resolution:resolution];

        PublishSpriteSheetOperation *operation = [[PublishSpriteSheetOperation alloc] initWithProjectSettings:_projectSettings
                                                                                                     warnings:_warnings
                                                                                                    publisher:self];
        operation.appDelegate = [AppDelegate appDelegate];
        operation.publishDirectory = publishDirectory;
        operation.publishedPNGFiles = _publishedPNGFiles;
        operation.publishedSpriteSheetNames = _publishedSpriteSheetNames;
        operation.srcSpriteSheetDate = srcSpriteSheetDate;
        operation.resolution = resolution;
        operation.srcDirs = @[[_projectSettings.tempSpriteSheetCacheDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"resources-%@", resolution]],
                              _projectSettings.tempSpriteSheetCacheDirectory];
        operation.spriteSheetFile = spriteSheetFile;
        operation.subPath = subPath;
        operation.targetType = _targetType;

        [_publishingQueue addOperation:operation];
	}
	
	[_publishedResources addObject:[subPath stringByAppendingPathExtension:@"plist"]];
	[_publishedResources addObject:[subPath stringByAppendingPathExtension:@"png"]];
}

- (BOOL)spriteSheetExistsAndUpToDate:(NSDate *)srcSpriteSheetDate spriteSheetFile:(NSString *)spriteSheetFile subPath:(NSString *)subPath
{
    NSDate* dstDate = [CCBFileUtil modificationDateForFile:[spriteSheetFile stringByAppendingPathExtension:@"plist"]];
    BOOL isDirty = [_projectSettings isDirtyRelPath:subPath];
    return dstDate
            && [dstDate isEqualToDate:srcSpriteSheetDate]
            && !isDirty;
}

- (void)prepareImagesForSpriteSheetPublishing:(NSString *)publishDirectory outDir:(NSString *)outDir resolution:(NSString *)resolution
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
                            outDir:outDir
                        resolution:resolution];
        }
    }
}

- (void)publishSpriteKitAtlasDir:(NSString *)spriteSheetDir sheetName:(NSString *)spriteSheetName subPath:(NSString *)subPath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSString *textureAtlasPath = [[NSBundle mainBundle] pathForResource:@"SpriteKitTextureAtlasToolPath" ofType:@"txt"];
    NSAssert(textureAtlasPath, @"Missing bundle file: SpriteKitTextureAtlasToolPath.txt");
    NSString *textureAtlasToolLocation = [NSString stringWithContentsOfFile:textureAtlasPath encoding:NSUTF8StringEncoding error:nil];
    NSLog(@"Using Sprite Kit Texture Atlas tool: %@", textureAtlasToolLocation);

    if ([fileManager fileExistsAtPath:textureAtlasToolLocation] == NO)
    {
        [_warnings addWarningWithDescription:@"<-- file not found! Install a public (non-beta) Xcode version to generate sprite sheets. Xcode beta users may edit 'SpriteKitTextureAtlasToolPath.txt' inside SpriteBuilder.app bundle." isFatal:YES relatedFile:textureAtlasToolLocation];
        return;
    }
	
	for (NSString* res in _publishForResolutions)
	{
        PublishSpriteKitSpriteSheetOperation *operation = [[PublishSpriteKitSpriteSheetOperation alloc] initWithProjectSettings:_projectSettings
                                                                                                                       warnings:_warnings
                                                                                                                      publisher:self];
        operation.resolution = res;
        operation.spriteSheetDir = spriteSheetDir;
        operation.spriteSheetName = spriteSheetName;
        operation.subPath = subPath;
        operation.textureAtlasToolLocation = textureAtlasPath;

        [_publishingQueue addOperation:operation];
    }
}

- (void)publishGeneratedFiles
{
    PublishGeneratedFilesOperation *operation = [[PublishGeneratedFilesOperation alloc] initWithProjectSettings:_projectSettings
                                                                                                       warnings:_warnings
                                                                                                      publisher:self];
    operation.targetType = _targetType;
    operation.outputDir = _outputDir;
    operation.publishedResources = _publishedResources;
    operation.publishedSpriteSheetFiles = _publishedSpriteSheetFiles;
    operation.fileLookup = _fileLookup;

    [_publishingQueue addOperation:operation];
}

- (BOOL)publishAllToDirectory:(NSString*)dir
{
    self.outputDir = dir;
    
    self.publishedResources = [NSMutableSet set];
    self.fileLookup = [[PublishFileLookup alloc] initWithFlattenPaths:_projectSettings.flattenPaths];

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

    if (!_runAfterPublishing)
    {
        if (![self publishIOS])
        {
            return NO;
        }
    }

    [_projectSettings clearAllDirtyMarkers];

    [self resetNeedRepublish];

    return YES;
}

- (BOOL)publishIOS
{
    // iOS publishing is the only os target at the moment
    // publishEnablediPhone = projectSettings.publishEnablediPhone;
    bool publishEnablediPhone = YES;

    if (!publishEnablediPhone)
    {
        return YES;
    }

    self.targetType = kCCBPublisherTargetTypeIPhone;
    _warnings.currentTargetType = _targetType;

    // NOTE: If android publishing is back this has to be changed accordingly
    self.publishForResolutions = [self.projectSettings publishingResolutionsForIOS];

    NSString *publishDir = [_projectSettings.publishDirectory absolutePathFromBaseDirPath:[_projectSettings.projectPath stringByDeletingLastPathComponent]];

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
        NSFileManager *fm = [NSFileManager defaultManager];
        NSString* publishDir;

        publishDir = [_projectSettings.publishDirectory absolutePathFromBaseDirPath:[_projectSettings.projectPath stringByDeletingLastPathComponent]];
        [fm removeItemAtPath:publishDir error:NULL];

        publishDir = [_projectSettings.publishDirectoryAndroid absolutePathFromBaseDirPath:[_projectSettings.projectPath stringByDeletingLastPathComponent]];
        [fm removeItemAtPath:publishDir error:NULL];

        publishDir = [_projectSettings.publishDirectoryHTML5 absolutePathFromBaseDirPath:[_projectSettings.projectPath stringByDeletingLastPathComponent]];
        [fm removeItemAtPath:publishDir error:NULL];
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
        OptimizeImageWithOptiPNGOperation *operation = [[OptimizeImageWithOptiPNGOperation alloc]  initWithProjectSettings:_projectSettings
                                                                                                                  warnings:_warnings
                                                                                                                 publisher:self];
        operation.appDelegate = [AppDelegate appDelegate];
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

    [self postProcessPublishedPNGFilesWithOptiPNG];

    _totalProgressUnits = [_publishingQueue operationCount];

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
    NSLog(@"Publishin cancelled by user");
    [_publishingQueue cancelAllOperations];
}



// TODO: can this be move to a mediator class or something else?
- (void)operationFinishedTick
{
    self.operationsFinished += 1;
    [self updateProgress];
}

- (void)updateProgress
{
    [[AppDelegate appDelegate] setProgress:(1.0 / _totalProgressUnits * _operationsFinished) * 100.0];
}

@end