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

#import "CCBDirectoryPublisher.h"
#import "ProjectSettings.h"
#import "CCBWarnings.h"
#import "NSString+RelativePath.h"
#import "PlugInManager.h"
#import "CCBGlobals.h"
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
#import "MiscConstants.h"
#import "PublishIntermediateFilesLookup.h"

@interface CCBDirectoryPublisher ()

@property (nonatomic, strong) NSArray *supportedFileExtensions;

@property (nonatomic, weak) NSOperationQueue *queue;
@property (nonatomic, weak) CCBWarnings *warnings;
@property (nonatomic, weak) ProjectSettings *projectSettings;

@end


@implementation CCBDirectoryPublisher

- (id)initWithProjectSettings:(ProjectSettings *)someProjectSettings warnings:(CCBWarnings *)someWarnings queue:(NSOperationQueue *)queue
{
    NSAssert(someProjectSettings != nil, @"project settings should never be nil! Publisher won't work without.");
    NSAssert(someWarnings != nil, @"warnings are nil. Are you sure you don't need them?");
    NSAssert(queue != nil, @"queue must not be nil");

    self = [super init];

	if (self)
	{
        self.queue = queue;
        self.projectSettings = someProjectSettings;
        self.warnings = someWarnings;

        self.modifiedDatesCache = [[DateCache alloc] init];

        self.supportedFileExtensions = @[@"jpg", @"png", @"psd", @"pvr", @"ccz", @"plist", @"fnt", @"ttf",@"js", @"json", @"wav",@"mp3",@"m4a",@"caf",@"ccblang"];
	}

    return self;
}

- (BOOL)publishImageForResolutions:(NSString *)srcFile
                                to:(NSString *)dstFile
                     isSpriteSheet:(BOOL)isSpriteSheet
                            outDir:(NSString *)outDir
                        fileLookup:(id <PublishFileLookupProtocol>)fileLookup
{
    for (NSString* resolution in _resolutions)
    {
        [self publishImageFile:srcFile to:dstFile isSpriteSheet:isSpriteSheet outputDir:outDir resolution:resolution intermediateProduct:NO fileLookup:fileLookup];
	}

    return YES;
}

- (BOOL)publishImageFile:(NSString *)srcFilePath
                      to:(NSString *)dstFilePath
           isSpriteSheet:(BOOL)isSpriteSheet
               outputDir:(NSString *)outputDir
              resolution:(NSString *)resolution
     intermediateProduct:(BOOL)intermediateProduct
              fileLookup:(id<PublishFileLookupProtocol>)fileLookup
{
    PublishImageOperation *operation = [[PublishImageOperation alloc] initWithProjectSettings:_projectSettings
                                                                                     warnings:_warnings
                                                                               statusProgress:_publishingTaskStatusProgress];

    operation.srcFilePath = srcFilePath;
    operation.dstFilePath = dstFilePath;
    operation.isSpriteSheet = isSpriteSheet;
    operation.outputDir = outputDir;
    operation.resolution = resolution;
    operation.osType = _osType;
    operation.modifiedFileDateCache = _modifiedDatesCache;
    operation.intermediateProduct = intermediateProduct;
    operation.publishedPNGFiles = _publishedPNGFiles;
    operation.fileLookup = fileLookup;

    [_queue addOperation:operation];
    return YES;
}

- (void)publishSoundFile:(NSString *)srcFilePath to:(NSString *)dstFilePath
{
    NSString *relPath = [_projectSettings findRelativePathInPackagesForAbsolutePath:srcFilePath];
    if (!relPath)
    {
        [_warnings addWarningWithDescription:[NSString stringWithFormat:@"Could not find relative path for Sound file: \"%@\"", srcFilePath] isFatal:YES];
        return;
    }

    int format = [_projectSettings soundFormatForRelPath:relPath osType:_osType];
    NSInteger quality = [_projectSettings soundQualityForRelPath:relPath osType:_osType];
    if (quality == NSNotFound)
    {
        quality = _audioQuality;
    }

    if (format == -1)
    {
        [_warnings addWarningWithDescription:[NSString stringWithFormat:@"Invalid sound conversion format for \"%@\"", relPath] isFatal:YES];
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

    [_queue addOperation:operation];
}

- (void)publishRegularFile:(NSString *)srcFilePath to:(NSString*)dstFilePath
{
    PublishRegularFileOperation *operation = [[PublishRegularFileOperation alloc] initWithProjectSettings:_projectSettings
                                                                                                 warnings:_warnings
                                                                                           statusProgress:_publishingTaskStatusProgress];
    operation.srcFilePath = srcFilePath;
    operation.dstFilePath = dstFilePath;

    [_queue addOperation:operation];
}

- (BOOL)publishDirectory:(NSString *)publishDirectory subPath:(NSString *)subPath
{
	NSString *outDir = [_outputDir stringByAppendingPathComponent:subPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];

    BOOL isGeneratedSpriteSheet = [[_projectSettings propertyForRelPath:subPath andKey:@"isSmartSpriteSheet"] boolValue];
    if (!isGeneratedSpriteSheet)
	{
        [_queue addOperationWithBlock:^
        {
            BOOL createdDirs = [fileManager createDirectoryAtPath:outDir withIntermediateDirectories:YES attributes:NULL error:NULL];
            if (!createdDirs)
            {
                [_warnings addWarningWithDescription:@"Failed to create output directory \"%@\"" isFatal:YES];
            }
        }];
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
                      publishDirectory:publishDirectory
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
	[files addObjectsFromArray:[publishDirectory resolutionDependantFilesInDirWithResolutions:_resolutions]];
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
          outputDir:(NSString *)outputDir
        isGeneratedSpriteSheet:(BOOL)isGeneratedSpriteSheet
{
    if ([self isIgnorableFile:fileName])
    {
        return YES;
    }

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
            [self publishImageForResolutions:filePath to:dstFilePath isSpriteSheet:isGeneratedSpriteSheet outDir:outputDir fileLookup:_renamedFilesLookup];
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

- (BOOL)isIgnorableFile:(NSString *)fileName
{
    return [fileName isIntermediateFileLookup]
           || [fileName isPackagePublishSettingsFile];
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

    [_queue addOperation:operation];
}


- (void)publishBMFont:(NSString *)directoryName dirPath:(NSString *)dirPath outputDir:(NSString *)outputDir
{
    NSString *bmFontOutDir = [outputDir stringByAppendingPathComponent:directoryName];
    [self publishRegularFile:dirPath to:bmFontOutDir];

    // Run after regular file has been copied, else png files cannot be found
    [_queue addOperationWithBlock:^
            {
                [_publishedPNGFiles addObjectsFromArray:[bmFontOutDir allPNGFilesInPath]];
            }];

    return;
}

- (void)publishSpriteSheetDir:(NSString *)spriteSheetDir
                    sheetName:(NSString *)spriteSheetName
             publishDirectory:(NSString *)publishDirectory
                      subPath:(NSString *)subPath
                    outputDir:(NSString *)outputDir
{
    // NOTE: For every spritesheet one shared dir is used, so we have to remove it on the
    // queue to ensure that later spritesheets don't add more sprites from previous passes
    [_queue addOperationWithBlock:^
    {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager removeItemAtPath:[_projectSettings tempSpriteSheetCacheDirectory] error:NULL];
    }];

    NSDate *srcSpriteSheetDate = [publishDirectory latestModifiedDateOfPathIgnoringDirs:YES];

	[_publishedSpriteSheetFiles addObject:[subPath stringByAppendingPathExtension:@"plist"]];

    [PublishSpriteSheetOperation resetSpriteSheetPreviewsGeneration];

	for (NSString *resolution in _resolutions)
	{
		NSString *spriteSheetFile = [[spriteSheetDir stringByAppendingPathComponent:[NSString stringWithFormat:@"resources-%@", resolution]] stringByAppendingPathComponent:spriteSheetName];

        NSString *intermediateFileLookupPath = [publishDirectory  stringByAppendingPathComponent:INTERMEDIATE_FILE_LOOKUP_NAME];
        [_renamedFilesLookup addIntermediateLookupPath:intermediateFileLookupPath];

		if ([self spriteSheetExistsAndUpToDate:srcSpriteSheetDate spriteSheetFile:spriteSheetFile subPath:subPath])
		{
            LocalLog(@"[SPRITESHEET] SKIPPING exists and up to date - file name: %@, subpath: %@, resolution: %@, file path: %@", [spriteSheetFile lastPathComponent], subPath, resolution, spriteSheetFile);
			continue;
		}

        // Note: these lookups are written as intermediate products to generate the final fileLookup.plist
        PublishIntermediateFilesLookup *publishIntermediateFilesLookup = [[PublishIntermediateFilesLookup alloc] init];

        [self prepareImagesForSpriteSheetPublishing:publishDirectory
                                          outputDir:outputDir
                                         resolution:resolution
                                         fileLookup:publishIntermediateFilesLookup];

        PublishSpriteSheetOperation *operation = [self createSpriteSheetOperation:publishDirectory
                                                                          subPath:subPath
                                                               srcSpriteSheetDate:srcSpriteSheetDate
                                                                       resolution:resolution
                                                                  spriteSheetFile:spriteSheetFile];

        [_queue addOperation:operation];

        [_queue addOperationWithBlock:^
        {
            if (![publishIntermediateFilesLookup writeToFile:intermediateFileLookupPath])
            {
                [_warnings addWarningWithDescription:[NSString stringWithFormat:@"Could not write intermediate file lookup for smart spritesheet %@ @ %@", spriteSheetName, resolution]];
            }
            [CCBFileUtil setModificationDate:srcSpriteSheetDate forFile:intermediateFileLookupPath];
        }];
	}
}

- (PublishSpriteSheetOperation *)createSpriteSheetOperation:(NSString *)publishDirectory
                                                    subPath:(NSString *)subPath
                                         srcSpriteSheetDate:(NSDate *)srcSpriteSheetDate
                                                 resolution:(NSString *)resolution
                                            spriteSheetFile:(NSString *)spriteSheetFile
{
    PublishSpriteSheetOperation *operation = [[PublishSpriteSheetOperation alloc] initWithProjectSettings:_projectSettings
                                                                                                 warnings:_warnings
                                                                                           statusProgress:_publishingTaskStatusProgress];
    operation.publishDirectory = publishDirectory;
    operation.publishedPNGFiles = _publishedPNGFiles;
    operation.srcSpriteSheetDate = srcSpriteSheetDate;
    operation.resolution = resolution;
    operation.srcDirs = @[
            [_projectSettings.tempSpriteSheetCacheDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"resources-%@", resolution]],
            _projectSettings.tempSpriteSheetCacheDirectory];
    operation.spriteSheetFile = spriteSheetFile;
    operation.subPath = subPath;
    operation.osType = _osType;
    return operation;
}

- (BOOL)spriteSheetExistsAndUpToDate:(NSDate *)srcSpriteSheetDate spriteSheetFile:(NSString *)spriteSheetFile subPath:(NSString *)subPath
{
    NSDate* dstDate = [CCBFileUtil modificationDateForFile:[spriteSheetFile stringByAppendingPathExtension:@"plist"]];
    BOOL isDirty = [_projectSettings isDirtyRelPath:subPath];
    return dstDate
            && [dstDate isEqualToDate:srcSpriteSheetDate]
            && !isDirty;
}

- (void)prepareImagesForSpriteSheetPublishing:(NSString *)publishDirectory
                                    outputDir:(NSString *)outputDir
                                   resolution:(NSString *)resolution
                                   fileLookup:(id<PublishFileLookupProtocol>)fileLookup
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
                        resolution:resolution
               intermediateProduct:YES
                        fileLookup:fileLookup];
        }
    }
}

- (void)publishSpriteKitAtlasDir:(NSString *)spriteSheetDir
                       sheetName:(NSString *)spriteSheetName
                         subPath:(NSString *)subPath
                publishDirectory:(NSString *)publishDirectory
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
	
	for (NSString* resolution in _resolutions)
	{
        NSString *intermediateFileLookupPath = [publishDirectory stringByAppendingPathComponent:INTERMEDIATE_FILE_LOOKUP_NAME];
        [_renamedFilesLookup addIntermediateLookupPath:intermediateFileLookupPath];

        // Note: these lookups are written as intermediate products to generate the final fileLookup.plist
        PublishIntermediateFilesLookup *publishIntermediateFilesLookup = [[PublishIntermediateFilesLookup alloc] init];

        [self prepareImagesForSpriteSheetPublishing:publishDirectory
                                          outputDir:outputDir
                                         resolution:resolution
                                         fileLookup:publishIntermediateFilesLookup];

        PublishSpriteKitSpriteSheetOperation *operation = [self createSpriteKitSheetOperation:spriteSheetDir
                                                                              spriteSheetName:spriteSheetName
                                                                                      subPath:subPath
                                                                     textureAtlasToolLocation:textureAtlasToolLocation
                                                                                   resolution:resolution];
        [_queue addOperation:operation];

        [_queue addOperationWithBlock:^{
            if (![publishIntermediateFilesLookup writeToFile:intermediateFileLookupPath])
            {
                [_warnings addWarningWithDescription:[NSString stringWithFormat:@"Could not write intermediate file lookup for smart spritesheet %@ @ %@", spriteSheetName, resolution]];
            }
        }];
    }
}

- (PublishSpriteKitSpriteSheetOperation *)createSpriteKitSheetOperation:(NSString *)spriteSheetDir
                                                        spriteSheetName:(NSString *)spriteSheetName
                                                                subPath:(NSString *)subPath
                                               textureAtlasToolLocation:(NSString *)textureAtlasToolLocation
                                                             resolution:(NSString *)resolution
{
    PublishSpriteKitSpriteSheetOperation *operation = [[PublishSpriteKitSpriteSheetOperation alloc] initWithProjectSettings:_projectSettings
                                                                                                                   warnings:_warnings
                                                                                                             statusProgress:_publishingTaskStatusProgress];
    operation.resolution = resolution;
    operation.spriteSheetDir = spriteSheetDir;
    operation.spriteSheetName = spriteSheetName;
    operation.subPath = subPath;
    operation.textureAtlasToolFilePath = textureAtlasToolLocation;
    return operation;
}

- (BOOL)generateAndEnqueuePublishingTasks
{
    NSAssert(_publishedPNGFiles != nil, @"publishedPNGFiles must not be nil");
    NSAssert(_inputDir != nil, @"inputDir must not be nil");
    NSAssert(_outputDir != nil, @"outputDir must not be nil");
    NSAssert(_resolutions != nil, @"resolutions must not be nil");
    NSAssert(_publishedSpriteSheetFiles != nil, @"publishedSpriteSheetFiles must not be nil");
    NSAssert(_renamedFilesLookup != nil, @"renamedFilesLookup must not be nil");

    return [self publishDirectory:_inputDir subPath:nil];
}

@end