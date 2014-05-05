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
#import "PlugInExport.h"
#import "PlugInManager.h"
#import "CCBGlobals.h"
#import "AppDelegate.h"
#import "NSString+AppendToFile.h"
#import "ResourceManager.h"
#import "CCBFileUtil.h"
#import "Tupac.h"
#import "CCBPublisherTemplate.h"
#import "CCBDirectoryComparer.h"
#import "ResourceManager.h"
#import "ResourceManagerUtil.h"
#import "FCFormatConverter.h"
#import "NSArray+Query.h"
#import "SBUserDefaultsKeys.h"
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

@interface CCBPublisher ()

@property (nonatomic) NSUInteger operationsFinished;
@property (nonatomic) NSUInteger totalProgressUnits;
@property (nonatomic, strong) PublishFileLookup *fileLookup;

@end

@implementation CCBPublisher
{
    DateCache *_modifiedDatesCache;
    NSMutableSet *_publishedPNGFiles;
    NSOperationQueue *_publishingQueue;
}

- (id)initWithProjectSettings:(ProjectSettings *)someProjectSettings warnings:(CCBWarnings *)someWarnings
{
    self = [super init];
	if (!self)
	{
		return NULL;
	}

    _modifiedDatesCache = [[DateCache alloc] init];

    _publishedPNGFiles = [NSMutableSet set];

    _publishingQueue = [[NSOperationQueue alloc] init];
    _publishingQueue.maxConcurrentOperationCount = 1;

    projectSettings = someProjectSettings;
    warnings = someWarnings;

    copyExtensions = @[@"jpg", @"png", @"psd", @"pvr", @"ccz", @"plist", @"fnt", @"ttf",@"js", @"json", @"wav",@"mp3",@"m4a",@"caf",@"ccblang"];
    
    publishedSpriteSheetNames = [[NSMutableArray alloc] init];
    publishedSpriteSheetFiles = [[NSMutableSet alloc] init];

    return self;
}

- (BOOL)publishImageForResolutionsWithFile:(NSString *)srcFile to:(NSString *)dstFile isSpriteSheet:(BOOL)isSpriteSheet outDir:(NSString *)outDir
{
    for (NSString* resolution in publishForResolutions)
    {
        [self publishImageFile:srcFile to:dstFile isSpriteSheet:isSpriteSheet outDir:outDir resolution:resolution];
	}

    return YES;
}

- (BOOL)publishImageFile:(NSString *)srcPath to:(NSString *)dstPath isSpriteSheet:(BOOL)isSpriteSheet outDir:(NSString *)outDir resolution:(NSString *)resolution
{
    PublishImageOperation *operation = [[PublishImageOperation alloc] initWithProjectSettings:projectSettings
                                                                                     warnings:warnings
                                                                                    publisher:self];
    operation.srcPath = srcPath;
    operation.dstPath = dstPath;
    operation.isSpriteSheet = isSpriteSheet;
    operation.outDir = outDir;
    operation.resolution = resolution;
    operation.targetType = targetType;
    operation.publishedResources = publishedResources;
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

    int format = [projectSettings soundFormatForRelPath:relPath targetType:targetType];
    int quality = [projectSettings soundQualityForRelPath:relPath targetType:targetType];
    if (format == -1)
    {
        [warnings addWarningWithDescription:[NSString stringWithFormat:@"Invalid sound conversion format for %@", relPath] isFatal:YES];
        return;
    }

    PublishSoundFileOperation *operation = [[PublishSoundFileOperation alloc] initWithProjectSettings:projectSettings
                                                                                             warnings:warnings
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
    PublishRegularFileOperation *operation = [[PublishRegularFileOperation alloc] initWithProjectSettings:projectSettings
                                                                                                 warnings:warnings
                                                                                                publisher:self];

    operation.srcFilePath = srcPath;
    operation.dstFilePath = dstPath;

    [_publishingQueue addOperation:operation];
}

- (BOOL)publishDirectory:(NSString *)publishDirectory subPath:(NSString *)subPath
{
	NSString *outDir = [self outputDirectory:subPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];

    BOOL isGeneratedSpriteSheet = [[projectSettings valueForRelPath:subPath andKey:@"isSmartSpriteSheet"] boolValue];
    if (!isGeneratedSpriteSheet)
	{
        BOOL createdDirs = [fileManager createDirectoryAtPath:outDir withIntermediateDirectories:YES attributes:NULL error:NULL];
        if (!createdDirs)
        {
            [warnings addWarningWithDescription:@"Failed to create output directory %@" isFatal:YES];
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
    BOOL publishForSpriteKit = projectSettings.engine == CCBTargetEngineSpriteKit;
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
	[files addObjectsFromArray:[self filesForResolutionDependantDirs:publishDirectory]];
	[files addObjectsFromArray:[self filesOfAutoDirectory:publishDirectory]];

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
                          filePath:filePath
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
    NSString *ext = [[fileName pathExtension] lowercaseString];

    // Skip non png files for generated sprite sheets
    if (isGeneratedSpriteSheet
        && ![fileName isSmartSpriteSheetCompatibleFile])
    {
        [warnings addWarningWithDescription:[NSString stringWithFormat:@"Non-png|psd file in smart sprite sheet (%@)", [fileName lastPathComponent]] isFatal:NO relatedFile:subPath];
        return YES;
    }

    if ([copyExtensions containsObject:ext]
        && !projectSettings.onlyPublishCCBs)
    {
        NSString *dstFilePath = [outDir stringByAppendingPathComponent:fileName];

        if (!isGeneratedSpriteSheet
            && ([fileName isSmartSpriteSheetCompatibleFile]))
        {
            [self publishImageForResolutionsWithFile:filePath to:dstFilePath isSpriteSheet:isGeneratedSpriteSheet outDir:outDir];
        }
        else if ([fileName isSoundFile])
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

- (void)publishCCB:(NSString *)fileName filePath:(NSString *)filePath outDir:(NSString *)outDir
{
    NSString *dstFile = [[outDir stringByAppendingPathComponent:[fileName stringByDeletingPathExtension]]
                                 stringByAppendingPathExtension:projectSettings.exporter];

    // Add file to list of published files
    NSString *localFileName = [dstFile relativePathFromBaseDirPath:outputDir];
    // TODO: move to base class or to a delegate
    [publishedResources addObject:localFileName];

    PublishCCBOperation *operation = [[PublishCCBOperation alloc] initWithProjectSettings:projectSettings
                                                                                 warnings:warnings
                                                                                publisher:self];
    operation.fileName = fileName;
    operation.filePath = filePath;
    operation.dstFile = dstFile;
    operation.outDir = outDir;

    [_publishingQueue addOperation:operation];
}

- (void)processDirectory:(NSString *)directory
                 subPath:(NSString *)subPath
                filePath:(NSString *)filePath
      resIndependentDirs:(NSArray *)resIndependentDirs
                  outDir:(NSString *)outDir
  isGeneratedSpriteSheet:(BOOL)isGeneratedSpriteSheet
{
    NSFileManager *fileManager = [NSFileManager defaultManager];

    if ([[filePath pathExtension] isEqualToString:@"bmfont"])
    {
        // This is a bitmap font, just copy it
        NSString *bmFontOutDir = [outDir stringByAppendingPathComponent:directory];
        [self publishRegularFile:filePath to:bmFontOutDir];

        NSArray *pngFiles = [self searchForPNGFilesInDirectory:bmFontOutDir];
        // TODO: this can be generalized
        [_publishedPNGFiles addObjectsFromArray:pngFiles];

        return;
    }

    // Skip resource independent directories
    if ([resIndependentDirs containsObject:directory])
    {
        return;
    }

    // Skip directories in generated sprite sheets
    if (isGeneratedSpriteSheet)
    {
        [warnings addWarningWithDescription:[NSString stringWithFormat:@"Generated sprite sheets do not support directories (%@)", [directory lastPathComponent]] isFatal:NO relatedFile:subPath];
        return;
    }

    // Skip the empty folder
    if ([[fileManager contentsOfDirectoryAtPath:filePath error:NULL] count] == 0)
    {
        return;
    }

    // Skip the fold no .ccb files when onlyPublishCCBs is true
    if (projectSettings.onlyPublishCCBs && ![self containsCCBFile:filePath])
    {
        return;
    }

    // This is a directory
    NSString *childPath = subPath
        ? [NSString stringWithFormat:@"%@/%@", subPath, directory]
        : directory;

    [self publishDirectory:filePath subPath:childPath];
}

- (NSArray *)searchForPNGFilesInDirectory:(NSString *)dir
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtURL:[NSURL URLWithString:dir]
                                          includingPropertiesForKeys:@[NSURLNameKey, NSURLIsDirectoryKey]
                                                             options:NSDirectoryEnumerationSkipsHiddenFiles
                                                        errorHandler:^BOOL(NSURL *url, NSError *error)
    {
        return YES;
    }];

    NSMutableArray *mutableFileURLs = [NSMutableArray array];
    for (NSURL *fileURL in enumerator)
    {
        NSString *filename;
        [fileURL getResourceValue:&filename forKey:NSURLNameKey error:nil];

        NSNumber *isDirectory;
        [fileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];

        if (![isDirectory boolValue] && [[fileURL relativeString] hasSuffix:@"png"])
        {
            [mutableFileURLs addObject:fileURL];
        }
    }

    return mutableFileURLs;
}

- (NSArray *)filesOfAutoDirectory:(NSString *)publishDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];;
	NSMutableArray *result = [NSMutableArray array];
	NSString* autoDir = [publishDirectory stringByAppendingPathComponent:@"resources-auto"];
	BOOL isDirAuto;
	if ([fileManager fileExistsAtPath:autoDir isDirectory:&isDirAuto] && isDirAuto)
    {
        [result addObjectsFromArray:[fileManager contentsOfDirectoryAtPath:autoDir error:NULL]];
    }
	return result;
}

- (NSArray *)filesForResolutionDependantDirs:(NSString *)dir
{
    NSFileManager *fileManager = [NSFileManager defaultManager];;
	NSMutableArray *result = [NSMutableArray array];

	for (NSString *publishExt in publishForResolutions)
	{
		NSString *resolutionDir = [dir stringByAppendingPathComponent:publishExt];
		BOOL isDirectory;
		if ([fileManager fileExistsAtPath:resolutionDir isDirectory:&isDirectory] && isDirectory)
		{
			[result addObjectsFromArray:[fileManager contentsOfDirectoryAtPath:resolutionDir error:NULL]];
		}
	}

	return result;
}

- (NSString *)outputDirectory:(NSString *)subPath
{
	NSString *outDir;
	if (projectSettings.flattenPaths && projectSettings.publishToZipFile)
    {
        outDir = outputDir;
    }
    else
    {
        outDir = [outputDir stringByAppendingPathComponent:subPath];
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
        [fileManager removeItemAtPath:[projectSettings tempSpriteSheetCacheDirectory] error:NULL];
    }];

    NSDate *srcSpriteSheetDate = [publishDirectory latestModifiedDateForDirectory];

	[publishedSpriteSheetFiles addObject:[subPath stringByAppendingPathExtension:@"plist"]];

	for (NSString *resolution in publishForResolutions)
	{
		NSString *spriteSheetFile = [[spriteSheetDir stringByAppendingPathComponent:[NSString stringWithFormat:@"resources-%@", resolution]] stringByAppendingPathComponent:spriteSheetName];

		if ([self spriteSheetExistsAndUpToDate:srcSpriteSheetDate spriteSheetFile:spriteSheetFile subPath:subPath])
		{
			continue;
		}

        [self prepareImagesForSpriteSheetPublishing:publishDirectory outDir:outDir resolution:resolution];

        PublishSpriteSheetOperation *operation = [[PublishSpriteSheetOperation alloc] initWithProjectSettings:projectSettings
                                                                                                     warnings:warnings
                                                                                                    publisher:self];
        operation.appDelegate = [AppDelegate appDelegate];
        operation.publishDirectory = publishDirectory;
        operation.publishedPNGFiles = _publishedPNGFiles;
        operation.publishedSpriteSheetNames = publishedSpriteSheetNames;
        operation.srcSpriteSheetDate = srcSpriteSheetDate;
        operation.resolution = resolution;
        operation.srcDirs = @[[projectSettings.tempSpriteSheetCacheDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"resources-%@", resolution]],
                              projectSettings.tempSpriteSheetCacheDirectory];
        operation.spriteSheetFile = spriteSheetFile;
        operation.subPath = subPath;
        operation.targetType = targetType;

        [_publishingQueue addOperation:operation];
	}
	
	[publishedResources addObject:[subPath stringByAppendingPathExtension:@"plist"]];
	[publishedResources addObject:[subPath stringByAppendingPathExtension:@"png"]];
}

- (BOOL)spriteSheetExistsAndUpToDate:(NSDate *)srcSpriteSheetDate spriteSheetFile:(NSString *)spriteSheetFile subPath:(NSString *)subPath
{
    NSDate* dstDate = [CCBFileUtil modificationDateForFile:[spriteSheetFile stringByAppendingPathExtension:@"plist"]];
    BOOL isDirty = [projectSettings isDirtyRelPath:subPath];
    return dstDate
            && [dstDate isEqualToDate:srcSpriteSheetDate]
            && !isDirty;
}

- (void)prepareImagesForSpriteSheetPublishing:(NSString *)publishDirectory outDir:(NSString *)outDir resolution:(NSString *)resolution
{
    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSMutableSet *files = [NSMutableSet setWithArray:[fileManager contentsOfDirectoryAtPath:publishDirectory error:NULL]];
	[files addObjectsFromArray:[self filesForResolutionDependantDirs:publishDirectory]];
    [files addObjectsFromArray:[self filesOfAutoDirectory:publishDirectory]];

    for (NSString *fileName in files)
    {
        NSString *filePath = [publishDirectory stringByAppendingPathComponent:fileName];

        if ([filePath isResourceAutoFile]
            && ([fileName isSmartSpriteSheetCompatibleFile]))
        {
            NSString *dstFile = [[projectSettings tempSpriteSheetCacheDirectory] stringByAppendingPathComponent:fileName];
            [self publishImageFile:filePath
                                to:dstFile
                     isSpriteSheet:NO
                            outDir:outDir
                        resolution:resolution];
        }
    }
}

// TODO move to own operation -> Stash
-(void) publishSpriteKitAtlasDir:(NSString*)spriteSheetDir sheetName:(NSString*)spriteSheetName subPath:(NSString*)subPath
{
	NSFileManager* fileManager = [NSFileManager defaultManager];

	NSString* textureAtlasPath = [[NSBundle mainBundle] pathForResource:@"SpriteKitTextureAtlasToolPath" ofType:@"txt"];
	NSAssert(textureAtlasPath, @"Missing bundle file: SpriteKitTextureAtlasToolPath.txt");
	NSString* textureAtlasToolLocation = [NSString stringWithContentsOfFile:textureAtlasPath encoding:NSUTF8StringEncoding error:nil];
	NSLog(@"Using Sprite Kit Texture Atlas tool: %@", textureAtlasToolLocation);
	
	if ([fileManager fileExistsAtPath:textureAtlasToolLocation] == NO)
	{
		[warnings addWarningWithDescription:@"<-- file not found! Install a public (non-beta) Xcode version to generate sprite sheets. Xcode beta users may edit 'SpriteKitTextureAtlasToolPath.txt' inside SpriteBuilder.app bundle." isFatal:YES relatedFile:textureAtlasToolLocation];
		return;
	}
	
	for (NSString* res in publishForResolutions)
	{
		// rename the resources-xxx folder for the atlas tool
		NSString* sourceDir = [projectSettings.tempSpriteSheetCacheDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"resources-%@", res]];
		NSString* sheetNameDir = [projectSettings.tempSpriteSheetCacheDirectory stringByAppendingPathComponent:spriteSheetName];
		[fileManager moveItemAtPath:sourceDir toPath:sheetNameDir error:nil];
		
		NSString* spriteSheetFile = [spriteSheetDir stringByAppendingPathComponent:[NSString stringWithFormat:@"resources-%@", res]];
		[fileManager createDirectoryAtPath:spriteSheetFile withIntermediateDirectories:YES attributes:nil error:nil];

		NSLog(@"Generating Sprite Kit Texture Atlas: %@", [NSString stringWithFormat:@"resources-%@/%@", res, spriteSheetName]);
		
		NSPipe* stdErrorPipe = [NSPipe pipe];
		[stdErrorPipe.fileHandleForReading readToEndOfFileInBackgroundAndNotify];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(spriteKitTextureAtlasTaskCompleted:) name:NSFileHandleReadToEndOfFileCompletionNotification object:stdErrorPipe.fileHandleForReading];
		
		// run task using Xcode TextureAtlas tool
		NSTask* atlasTask = [[NSTask alloc] init];
		atlasTask.launchPath = textureAtlasToolLocation;
		atlasTask.arguments = @[sheetNameDir, spriteSheetFile];
		atlasTask.standardOutput = stdErrorPipe;
		[atlasTask launch];
		
		// Update progress
		[[AppDelegate appDelegate] modalStatusWindowUpdateStatusText:[NSString stringWithFormat:@"Generating sprite sheet %@...", [[subPath stringByAppendingPathExtension:@"plist"] lastPathComponent]]];
		
		[atlasTask waitUntilExit];

		// rename back just in case
		[fileManager moveItemAtPath:sheetNameDir toPath:sourceDir error:nil];

		NSString* sheetPlist = [NSString stringWithFormat:@"resources-%@/%@.atlasc/%@.plist", res, spriteSheetName, spriteSheetName];
		NSString* sheetPlistPath = [spriteSheetDir stringByAppendingPathComponent:sheetPlist];
		if ([fileManager fileExistsAtPath:sheetPlistPath] == NO)
		{
			[warnings addWarningWithDescription:@"TextureAtlas failed to generate! See preceding error message(s)." isFatal:YES relatedFile:spriteSheetName resolution:res];
		}
		
		// TODO: ?? because SK TextureAtlas tool itself checks if the spritesheet needs to be updated
		/*
		 [CCBFileUtil setModificationDate:srcSpriteSheetDate forFile:[spriteSheetFile stringByAppendingPathExtension:@"plist"]];
		 [publishedResources addObject:[subPath stringByAppendingPathExtension:@"plist"]];
		 [publishedResources addObject:[subPath stringByAppendingPathExtension:@"png"]];
		 */
	}
}

-(void) spriteKitTextureAtlasTaskCompleted:(NSNotification *)notification
{
	// log additional warnings/errors from TextureAtlas tool
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadToEndOfFileCompletionNotification object:notification.object];

	NSData* data = [notification.userInfo objectForKey:NSFileHandleNotificationDataItem];
	NSString* errorMessage = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	if (errorMessage.length)
	{
		NSLog(@"%@", errorMessage);
		[warnings addWarningWithDescription:errorMessage isFatal:YES];
	}
}

- (BOOL) containsCCBFile:(NSString*) dir
{
    NSFileManager* fm = [NSFileManager defaultManager];
    NSArray* files = [fm contentsOfDirectoryAtPath:dir error:NULL];
    NSArray* resIndependentDirs = [ResourceManager resIndependentDirs];
    
    for (NSString* file in files) {
        BOOL isDirectory;
        NSString* filePath = [dir stringByAppendingPathComponent:file];
        
        if([fm fileExistsAtPath:filePath isDirectory:&isDirectory]){
            if(isDirectory){
                // Skip resource independent directories
                if ([resIndependentDirs containsObject:file]) {
                    continue;
                }else if([self containsCCBFile:filePath]){
                    return YES;
                }
            }else{
                if([[file lowercaseString] hasSuffix:@"ccb"]){
                    return YES;
                }
            }
        }
    }
    return NO;
}

- (void)publishGeneratedFiles
{
    PublishGeneratedFilesOperation *operation = [[PublishGeneratedFilesOperation alloc] initWithProjectSettings:projectSettings
                                                                                                       warnings:warnings
                                                                                                      publisher:self];
    operation.targetType = targetType;
    operation.outputDir = outputDir;
    operation.publishedResources = publishedResources;
    operation.publishedSpriteSheetFiles = publishedSpriteSheetFiles;
    operation.fileLookup = _fileLookup;

    [_publishingQueue addOperation:operation];
}

- (BOOL)publishAllToDirectory:(NSString*)dir
{
    outputDir = dir;
    
    publishedResources = [NSMutableSet set];
    self.fileLookup = [[PublishFileLookup alloc] initWithFlattenPaths:projectSettings.flattenPaths];

    // Publish resources and ccb-files
    for (NSString* aDir in projectSettings.absoluteResourcePaths)
    {
		if (![self publishDirectory:aDir subPath:NULL])
		{
			return NO;
		}
	}
    
    // Publish generated files
    if(!projectSettings.onlyPublishCCBs)
    {
        [self publishGeneratedFiles];
    }
    
    // Yiee Haa!
    return YES;
}

- (BOOL)publishArchive:(NSString*)file
{
    NSFileManager *manager = [NSFileManager defaultManager];
    
    // Remove the old file
    [manager removeItemAtPath:file error:NULL];
    
    // Zip it up!
    NSTask* zipTask = [[NSTask alloc] init];
    [zipTask setCurrentDirectoryPath:outputDir];
    
    [zipTask setLaunchPath:@"/usr/bin/zip"];
    NSArray* args = [NSArray arrayWithObjects:@"-r", @"-q", file, @".", @"-i", @"*", nil];
    [zipTask setArguments:args];
    [zipTask launch];
    [zipTask waitUntilExit];
    
    return [manager fileExistsAtPath:file];
}

- (BOOL) archiveToFile:(NSString*)file diffFrom:(NSDictionary*) diffFiles
{
    if (!diffFiles) diffFiles = [NSDictionary dictionary];
    
    NSFileManager *manager = [NSFileManager defaultManager];
    
    // Remove the old file
    [manager removeItemAtPath:file error:NULL];
    
    // Create diff
    CCBDirectoryComparer* dc = [[CCBDirectoryComparer alloc] init];
    [dc loadDirectory:outputDir];
    NSArray* fileList = [dc diffWithFiles:diffFiles];
    
    // Zip it up!
    NSTask* zipTask = [[NSTask alloc] init];
    [zipTask setCurrentDirectoryPath:outputDir];
    
    [zipTask setLaunchPath:@"/usr/bin/zip"];
    NSMutableArray* args = [NSMutableArray arrayWithObjects:@"-r", @"-q", file, @".", @"-i", nil];
    
    for (NSString* f in fileList)
    {
        [args addObject:f];
    }
    
    [zipTask setArguments:args];
    [zipTask launch];
    [zipTask waitUntilExit];
    
    return [manager fileExistsAtPath:file];
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

        // Android publishing disabled at the moment
        /*
        if (![self publishAndroid])
        {
            return NO;
        }
        */
    }

    [projectSettings clearAllDirtyMarkers];

    [self resetNeedRepublish];

    return YES;
}

- (BOOL)publishAndroid
{
    bool publishEnabledAndroid  = projectSettings.publishEnabledAndroid;
    if (!publishEnabledAndroid)
    {
        return YES;
    }

    targetType = kCCBPublisherTargetTypeAndroid;
    warnings.currentTargetType = targetType;

    [self configureResolutionsForAndroid];

    NSString* publishDir = [projectSettings.publishDirectoryAndroid absolutePathFromBaseDirPath:[projectSettings.projectPath stringByDeletingLastPathComponent]];

    if (projectSettings.publishToZipFile)
    {
        // Publish archive
        NSString *zipFile = [publishDir stringByAppendingPathComponent:@"ccb.zip"];

        if (![self publishArchive:zipFile])
        {
            return NO;
        }
    }
    else
    {
        // Publish files
        if (![self publishAllToDirectory:publishDir])
        {
            return NO;
        }
    }

    return YES;
}

- (BOOL)publishIOS
{
    // iOS publishing is the only os target at the moment
    bool publishEnablediPhone;
    // publishEnablediPhone = projectSettings.publishEnablediPhone;
    publishEnablediPhone = YES;

    if (!publishEnablediPhone)
    {
        return YES;
    }

    targetType = kCCBPublisherTargetTypeIPhone;
    warnings.currentTargetType = targetType;

    // NOTE: If android publishing is back this has to be changed accordingly
    [self connfigureResolutionsForIOS];

    NSString *publishDir = [projectSettings.publishDirectory absolutePathFromBaseDirPath:[projectSettings.projectPath stringByDeletingLastPathComponent]];

    if (projectSettings.publishToZipFile)
    {
        NSString *zipFile = [publishDir stringByAppendingPathComponent:@"ccb.zip"];
        if (![self publishArchive:zipFile])
        {
            return NO;
        }
    }
    else
    {
        if (![self publishAllToDirectory:publishDir])
        {
            return NO;
        }
    }
    return YES;
}

- (void)configureResolutionsForAndroid
{
    NSMutableArray* resolutions = [NSMutableArray array];

    if (projectSettings.publishResolution_android_phone)
    {
        [resolutions addObject:@"phone"];
    }
    if (projectSettings.publishResolution_android_phonehd)
    {
        [resolutions addObject:@"phonehd"];
    }
    if (projectSettings.publishResolution_android_tablet)
    {
        [resolutions addObject:@"tablet"];
    }
    if (projectSettings.publishResolution_android_tablethd)
    {
        [resolutions addObject:@"tablethd"];
    }
    publishForResolutions = resolutions;
}

- (void)connfigureResolutionsForIOS
{
    NSMutableArray* resolutions = [NSMutableArray array];

    if (projectSettings.publishResolution_ios_phone)
    {
        [resolutions addObject:@"phone"];
    }
    if (projectSettings.publishResolution_ios_phonehd)
    {
        [resolutions addObject:@"phonehd"];
    }
    if (projectSettings.publishResolution_ios_tablet)
    {
        [resolutions addObject:@"tablet"];
    }
    if (projectSettings.publishResolution_ios_tablethd)
    {
        [resolutions addObject:@"tablethd"];
    }
    publishForResolutions = resolutions;
}

- (void)resetNeedRepublish
{
    if (projectSettings.needRepublish)
    {
        projectSettings.needRepublish = NO;
        [projectSettings store];
    }
}

- (void)removeOldPublishDirIfCacheCleaned
{
    if (projectSettings.needRepublish && !projectSettings.onlyPublishCCBs)
    {
        NSFileManager *fm = [NSFileManager defaultManager];
        NSString* publishDir;

        publishDir = [projectSettings.publishDirectory absolutePathFromBaseDirPath:[projectSettings.projectPath stringByDeletingLastPathComponent]];
        [fm removeItemAtPath:publishDir error:NULL];

        publishDir = [projectSettings.publishDirectoryAndroid absolutePathFromBaseDirPath:[projectSettings.projectPath stringByDeletingLastPathComponent]];
        [fm removeItemAtPath:publishDir error:NULL];

        publishDir = [projectSettings.publishDirectoryHTML5 absolutePathFromBaseDirPath:[projectSettings.projectPath stringByDeletingLastPathComponent]];
        [fm removeItemAtPath:publishDir error:NULL];
    }
}

- (void)postProcessPublishedPNGFilesWithOptiPNG
{
    if ([projectSettings isPublishEnvironmentDebug])
    {
        return;
    }

    NSString *pathToOptiPNG = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"optipng"];
    if (!pathToOptiPNG)
    {
        // TODO: inform user that somethings wrong with the bundle
        NSLog(@"ERROR: optipng was not found.");
        return;
    }

    for (NSString *pngFile in _publishedPNGFiles)
    {
        OptimizeImageWithOptiPNGOperation *operation = [[OptimizeImageWithOptiPNGOperation alloc]  initWithProjectSettings:projectSettings
                                                                                                                  warnings:warnings
                                                                                                                 publisher:self];
        operation.appDelegate = [AppDelegate appDelegate];
        operation.filePath = pngFile;
        operation.optiPngPath = pathToOptiPNG;

        [_publishingQueue addOperation:operation];
    }
}

- (void)flagFilesWithWarningsAsDirty
{
	for (CCBWarning *warning in warnings.warnings)
	{
		if (warning.relatedFile)
		{
			[projectSettings markAsDirtyRelPath:warning.relatedFile];
		}
	}
}


#pragma mark - public methods

- (void)publish
{
    [self doPublish];

	[self flagFilesWithWarningsAsDirty];

    [[AppDelegate appDelegate] publisher:self finishedWithWarnings:warnings];
}

- (void)publishAsync
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
		NSLog(@"[PUBLISH] Start...");

        [_publishingQueue setSuspended:YES];

        NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];

        if (projectSettings.publishEnvironment == PublishEnvironmentRelease)
        {
            [CCBPublisher cleanAllCacheDirectoriesWithProjectSettings:projectSettings];
        }

        [self doPublish];

        [self postProcessPublishedPNGFilesWithOptiPNG];

        _totalProgressUnits = [_publishingQueue operationCount];

        [_publishingQueue setSuspended:NO];
        [_publishingQueue waitUntilAllOperationsAreFinished];

		[self flagFilesWithWarningsAsDirty];

		NSLog(@"[PUBLISH] Done in %.2f seconds.",  [[NSDate date] timeIntervalSince1970] - startTime);

        dispatch_sync(dispatch_get_main_queue(), ^
        {
            [[AppDelegate appDelegate] publisher:self finishedWithWarnings:warnings];
        });
    });
}

+ (void)cleanAllCacheDirectoriesWithProjectSettings:(ProjectSettings *)projectSettings
{
    NSAssert(projectSettings != nil, @"Project settings should not be nil.");

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