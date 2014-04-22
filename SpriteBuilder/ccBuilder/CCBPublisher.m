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
#import "ProjectSettings+SoundSettings.h"
#import "PublishCCBOperation.h"


@interface CCBPublisher()

// TODO not needed anymore after refactoring -> PublishCCBOperation
@property (nonatomic, copy) NSString *publishFormat;

@end

@implementation CCBPublisher
{
	NSMutableDictionary *_modifiedDatesCache;
    NSMutableSet *_publishedPNGFiles;

    NSOperationQueue *_publishingQueue;
}

- (NSDate *)cachedModifyDateForKey:(NSString *)key
{
	return [_modifiedDatesCache objectForKey:key];
}

- (void)setModifyCachedDate:(id)date forKey:(NSString *)key
{
	[_modifiedDatesCache setObject:date forKey:key];
}

- (id) initWithProjectSettings:(ProjectSettings*)settings warnings:(CCBWarnings*)w
{
    self = [super init];
	if (!self)
	{
		return NULL;
	}

	_modifiedDatesCache = [NSMutableDictionary dictionary];
    _publishedPNGFiles = [NSMutableSet set];
    _publishingQueue = [[NSOperationQueue alloc] init];
    _publishingQueue.maxConcurrentOperationCount = 1;

	// Save settings and warning log
    projectSettings = settings;
    warnings = w;
    
    // Setup extensions to copy
    copyExtensions = @[@"jpg", @"png", @"psd", @"pvr", @"ccz", @"plist", @"fnt", @"ttf",@"js", @"json", @"wav",@"mp3",@"m4a",@"caf",@"ccblang"];
    
    publishedSpriteSheetNames = [[NSMutableArray alloc] init];
    publishedSpriteSheetFiles = [[NSMutableSet alloc] init];
    
    // Set format to use for exports
    self.publishFormat = projectSettings.exporter;

    return self;
}

- (NSDate *)latestModifiedDateForDirectory:(NSString *)dir
{
	NSDate* latestDate = [CCBFileUtil modificationDateForFile:dir];

    NSArray* files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dir error:NULL];
    for (NSString* file in files)
    {
        NSString* absFile = [dir stringByAppendingPathComponent:file];

        BOOL isDir = NO;
        if ([[NSFileManager defaultManager] fileExistsAtPath:absFile isDirectory:&isDir])
        {
            NSDate* fileDate = NULL;
            
            if (isDir)
            {
				fileDate = [self latestModifiedDateForDirectory:absFile];
			}
            else
            {
				fileDate = [CCBFileUtil modificationDateForFile:absFile];
            }
            
            if ([fileDate compare:latestDate] == NSOrderedDescending)
            {
                latestDate = fileDate;
            }
        }
    }

    return latestDate;
}

- (void) addRenamingRuleFrom:(NSString*)src to: (NSString*)dst
{
    if (projectSettings.flattenPaths)
    {
        src = [src lastPathComponent];
        dst = [dst lastPathComponent];
    }
    
    if ([src isEqualToString:dst]) return;
    
    // Add the file to the dictionary
    [renamedFiles setObject:dst forKey:src];
}

-(NSString*) pathWithCocoaImageResolutionSuffix:(NSString*)path resolution:(NSString*)resolution
{
	NSString* extension = [path pathExtension];
	
	if ([resolution isEqualToString:@"phonehd"])
	{
		path = [NSString stringWithFormat:@"%@@2x.%@", [path stringByDeletingPathExtension], extension];
	}
	else if ([resolution isEqualToString:@"tablet"])
	{
		path = [NSString stringWithFormat:@"%@~ipad.%@", [path stringByDeletingPathExtension], extension];
	}
	else if ([resolution isEqualToString:@"tablethd"])
	{
		path = [NSString stringWithFormat:@"%@@2x~ipad.%@", [path stringByDeletingPathExtension], extension];
	}
	
	return path;
}

- (BOOL)publishImageForResolutionsWithFile:(NSString *)srcFile to:(NSString *)dstFile isSpriteSheet:(BOOL)isSpriteSheet outDir:(NSString *)outDir
{
    for (NSString* resolution in publishForResolutions)
    {
		if (![self publishImageFile:srcFile to:dstFile isSpriteSheet:isSpriteSheet outDir:outDir resolution:resolution])
		{
			return NO;
		}
	}
    
    return YES;
}

- (BOOL)publishImageFile:(NSString *)srcPath to:(NSString *)dstPath isSpriteSheet:(BOOL)isSpriteSheet outDir:(NSString *)outDir resolution:(NSString *)resolution
{
    NSString* relPath = [ResourceManagerUtil relativePathFromAbsolutePath:srcPath];

    if (isSpriteSheet
		&& [self isSpriteSheetAlreadyPublished:srcPath outDir:outDir resolution:resolution])
    {
		return NO;
	}

	[publishedResources addObject:relPath];

    [[AppDelegate appDelegate] modalStatusWindowUpdateStatusText:[NSString stringWithFormat:@"Publishing %@...", [dstPath lastPathComponent]]];
    
    // Find out which file to copy for the current resolution
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString* srcAutoPath = NULL;
    
    NSString* srcFileName = [srcPath lastPathComponent];
    NSString* dstFileName = [dstPath lastPathComponent];
    NSString* srcDir = [srcPath stringByDeletingLastPathComponent];
    NSString* dstDir = [dstPath stringByDeletingLastPathComponent];
    NSString* autoDir = [srcDir stringByAppendingPathComponent:@"resources-auto"];
    srcAutoPath = [autoDir stringByAppendingPathComponent:srcFileName];
    
    // Update path to reflect resolution
    srcDir = [srcDir stringByAppendingPathComponent:[@"resources-" stringByAppendingString:resolution]];
    dstDir = [dstDir stringByAppendingPathComponent:[@"resources-" stringByAppendingString:resolution]];
    
    srcPath = [srcDir stringByAppendingPathComponent:srcFileName];
    dstPath = [dstDir stringByAppendingPathComponent:dstFileName];
    
	// Sprite Kit requires specific extensions for specific image resolutions (ie @2x, ~ipad, ..)
	if (projectSettings.engine == CCBTargetEngineSpriteKit)
	{
		dstPath = [self pathWithCocoaImageResolutionSuffix:dstPath resolution:resolution];
	}

    // Create destination directory if it doesn't exist
    [fileManager createDirectoryAtPath:dstDir withIntermediateDirectories:YES attributes:NULL error:NULL];

    // Get the format of the published image
    int format = kFCImageFormatPNG;
    BOOL dither = NO;
    BOOL compress = NO;
    
    if (!isSpriteSheet)
    {
        if (targetType == kCCBPublisherTargetTypeIPhone)
        {
            format = [[projectSettings valueForRelPath:relPath andKey:@"format_ios"] intValue];
            dither = [[projectSettings valueForRelPath:relPath andKey:@"format_ios_dither"] boolValue];
            compress = [[projectSettings valueForRelPath:relPath andKey:@"format_ios_compress"] boolValue];
        }
        else if (targetType == kCCBPublisherTargetTypeAndroid)
        {
            format = [[projectSettings valueForRelPath:relPath andKey:@"format_android"] intValue];
            dither = [[projectSettings valueForRelPath:relPath andKey:@"format_android_dither"] boolValue];
            compress = [[projectSettings valueForRelPath:relPath andKey:@"format_android_compress"] boolValue];
        }
    }
    
    // Fetch new name
    NSString* dstPathProposal = [[FCFormatConverter defaultConverter] proposedNameForConvertedImageAtPath:dstPath format:format compress:compress isSpriteSheet:isSpriteSheet];
    
    // Add renaming rule
    NSString* relPathRenamed = [[FCFormatConverter defaultConverter] proposedNameForConvertedImageAtPath:relPath format:format compress:compress isSpriteSheet:isSpriteSheet];
	
    [self addRenamingRuleFrom:relPath to:relPathRenamed];
    
    // Copy and convert the image
    BOOL isDirty = [projectSettings isDirtyRelPath:relPath];
    
    if ([fileManager fileExistsAtPath:srcPath])
    {
        // Has customized file for resolution
        
        // Check if file already exists
        NSDate* srcDate = [CCBFileUtil modificationDateForFile:srcPath];
        NSDate* dstDate = [CCBFileUtil modificationDateForFile:dstPathProposal];
        
        if (dstDate && [srcDate isEqualToDate:dstDate] && !isDirty)
        {
            return YES;
        }
        
        // Copy file
        [fileManager copyItemAtPath:srcPath toPath:dstPath error:NULL];

        // Convert it
        NSString* dstPathConverted = nil;
        NSError  * error;

        if(![[FCFormatConverter defaultConverter] convertImageAtPath:dstPath format:format dither:dither compress:compress isSpriteSheet:isSpriteSheet outputFilename:&dstPathConverted error:&error])
        {
            [warnings addWarningWithDescription:[NSString stringWithFormat:@"Failed to convert image: %@. Error Message:%@", srcFileName, error.localizedDescription] isFatal:NO];
            return NO;
        }
        
        // Update modification date
        [CCBFileUtil setModificationDate:srcDate forFile:dstPathConverted];

        if (!isSpriteSheet && format == kFCImageFormatPNG)
        {
            [_publishedPNGFiles addObject:dstPathConverted];
        }

        return YES;
    }
    else if ([fileManager fileExistsAtPath:srcAutoPath])
    {
        // Use resources-auto file for conversion
        
        // Check if file already exist
        NSDate* srcDate = [CCBFileUtil modificationDateForFile:srcAutoPath];
        NSDate* dstDate = [CCBFileUtil modificationDateForFile:dstPathProposal];
        
        if (dstDate && [srcDate isEqualToDate:dstDate] && !isDirty)
        {
            return YES;
        }
        
        // Copy file and resize
        [[ResourceManager sharedManager] createCachedImageFromAuto:srcAutoPath saveAs:dstPath forResolution:resolution];
        
        // Convert it
        NSString* dstPathConverted = nil;
        NSError  * error;
        
        if(![[FCFormatConverter defaultConverter] convertImageAtPath:dstPath format:format dither:dither compress:compress isSpriteSheet:isSpriteSheet outputFilename:&dstPathConverted error:&error])
        {
            [warnings addWarningWithDescription:[NSString stringWithFormat:@"Failed to convert image: %@. Error Message:%@", srcFileName, error.localizedDescription] isFatal:NO];
            return NO;
        }
        
        // Update modification date
        [CCBFileUtil setModificationDate:srcDate forFile:dstPathConverted];

        if (!isSpriteSheet && format == kFCImageFormatPNG)
        {
            [_publishedPNGFiles addObject:dstPathConverted];
        }

        return YES;
    }
    else
    {
        // File is missing
        
        // Log a warning and continue publishing
        [warnings addWarningWithDescription:[NSString stringWithFormat:@"Failed to publish file %@, make sure it is in the resources-auto folder.",srcFileName] isFatal:NO];
        return YES;
    }
}

- (BOOL)isSpriteSheetAlreadyPublished:(NSString *)srcPath outDir:(NSString *)outDir resolution:(NSString *)resolution
{
	NSString* ssDir = [srcPath stringByDeletingLastPathComponent];
	NSString* ssDirRel = [ResourceManagerUtil relativePathFromAbsolutePath:ssDir];
	NSString* ssName = [ssDir lastPathComponent];

	NSDate *srcDate = [self modifiedDateOfSpriteSheetDirectory:ssDir];

	BOOL isDirty = [projectSettings isDirtyRelPath:ssDirRel];

	// Make the name for the final sprite sheet
	NSString* ssDstPath = [[[[outDir stringByDeletingLastPathComponent]
									 stringByAppendingPathComponent:[NSString stringWithFormat:@"resources-%@", resolution]]
									 stringByAppendingPathComponent:ssName] stringByAppendingPathExtension:@"plist"];

	NSDate *ssDstDate = [self modifiedDataOfSpriteSheetFile:ssDstPath];

	if (ssDstDate && [ssDstDate isEqualToDate:srcDate] && !isDirty)
	{
		return YES;
	}
	return NO;
}

- (NSDate *)modifiedDataOfSpriteSheetFile:(NSString *)spriteSheetFile
{
	id ssDstDate = [self cachedModifyDateForKey:spriteSheetFile];

	if ([ssDstDate isMemberOfClass:[NSNull class]])
	{
		return nil;
	}

	if (!ssDstDate)
	{
		ssDstDate = [CCBFileUtil modificationDateForFile:spriteSheetFile];
		// Storing NSNull since CCBFileUtil can return nil due to a non existing file
		// So we don't run into the whole fille IO process again, rather hit the cache and
		// bend the result here
		if (ssDstDate == nil)
		{
			[self setModifyCachedDate:[NSNull null] forKey:spriteSheetFile];
		}
		else
		{
			[self setModifyCachedDate:ssDstDate forKey:spriteSheetFile];
		}
	}

	return ssDstDate;
}

- (NSDate *)modifiedDateOfSpriteSheetDirectory:(NSString *)directory
{
	NSDate *srcDate = [self cachedModifyDateForKey:directory];
	if (!srcDate)
		{
			srcDate = [self latestModifiedDateForDirectory:directory];
			[self setModifyCachedDate:srcDate forKey:directory];
		}
	return srcDate;
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

    [self addRenamingRuleFrom:relPath to:[[FCFormatConverter defaultConverter] proposedNameForConvertedSoundAtPath:relPath
                                                                                                            format:format
                                                                                                           quality:quality]];

    PublishSoundFileOperation *operation = [[PublishSoundFileOperation alloc] initWithProjectSettings:projectSettings
                                                                                             warnings:warnings];

    operation.srcFilePath = srcPath;
    operation.dstFilePath = dstPath;
    operation.format = format;
    operation.quality = quality;

    [operation start];
    // [_publishingQueue addOperation:operation];
}

- (void)publishRegularFile:(NSString *)srcPath to:(NSString*) dstPath
{
    PublishRegularFileOperation *operation = [[PublishRegularFileOperation alloc] initWithSrcFilePath:srcPath
                                                                                          dstFilePath:dstPath];

    [operation start];
    // [_publishingQueue addOperation:operation];
}

- (BOOL)publishDirectory:(NSString *)publishDirectory subPath:(NSString *)subPath
{
	NSString *outDir = [self outputDirectory:subPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];

    BOOL isGeneratedSpriteSheet = [[projectSettings valueForRelPath:subPath andKey:@"isSmartSpriteSheet"] boolValue];
    if (isGeneratedSpriteSheet)
    {
        [fileManager removeItemAtPath:[projectSettings tempSpriteSheetCacheDirectory] error:NULL];
    }
	else
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
        [self processSpriteSheetDir:publishDirectory subPath:subPath outDir:outDir];
    }
    
    return YES;
}

- (void)processSpriteSheetDir:(NSString *)publishDirectory subPath:(NSString *)subPath outDir:(NSString *)outDir
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
                            subPath:subPath];
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
	[files addObjectsFromArray:[self filesForResolutionDependantDirs:publishDirectory fileManager:fileManager]];
	[files addObjectsFromArray:[self filesOfAutoDirectory:publishDirectory fileManager:fileManager]];

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
    if (isGeneratedSpriteSheet && !([ext isEqualToString:@"png"] || [ext isEqualToString:@"psd"]))
    {
        [warnings addWarningWithDescription:[NSString stringWithFormat:@"Non-png file in smart sprite sheet (%@)", [fileName lastPathComponent]] isFatal:NO relatedFile:subPath];
        return YES;
    }

    if ([copyExtensions containsObject:ext] && !projectSettings.onlyPublishCCBs)
    {
        // Get destination file name
        NSString *dstFile = [outDir stringByAppendingPathComponent:fileName];

        // Copy file (and possibly convert)
        if ([ext isEqualToString:@"png"] || [ext isEqualToString:@"psd"])
        {
            // Use temp cache directory for generated sprite sheets
            if (isGeneratedSpriteSheet)
            {
                dstFile = [[projectSettings tempSpriteSheetCacheDirectory] stringByAppendingPathComponent:fileName];
            }

            // Publish images
            [self publishImageForResolutionsWithFile:filePath to:dstFile isSpriteSheet:isGeneratedSpriteSheet outDir:outDir];
        }
        else if ([ext isEqualToString:@"wav"])
        {
            // Publish sounds
            [self publishSoundFile:filePath to:dstFile];
        }
        else
        {
            // Publish any other type of file
            [self publishRegularFile:filePath to:dstFile];
        }
    }
    else if ([[fileName lowercaseString] hasSuffix:@"ccb"] && !isGeneratedSpriteSheet)
    {
        [self publishCCB:fileName filePath:filePath outDir:outDir];
    }
    return YES;
}

- (void)publishCCB:(NSString *)fileName filePath:(NSString *)filePath outDir:(NSString *)outDir
{
    NSString *dstFile = [[outDir stringByAppendingPathComponent:[fileName stringByDeletingPathExtension]]
                                 stringByAppendingPathExtension:_publishFormat];

    // Add file to list of published files
    NSString *localFileName = [dstFile relativePathFromBaseDirPath:outputDir];
    // TODO: move to base class or to a delegate
    [publishedResources addObject:localFileName];

    PublishCCBOperation *operation = [[PublishCCBOperation alloc] initWithProjectSettings:projectSettings warnings:warnings];
    operation.fileName = fileName;
    operation.filePath = filePath;
    operation.dstFile = dstFile;
    operation.outDir = outDir;

    [operation start];
    // [_publishingQueue addOperation:operation];
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

- (NSArray *)filesOfAutoDirectory:(NSString *)publishDirectory fileManager:(NSFileManager *)fileManager
{
	NSMutableArray *result = [NSMutableArray array];
	NSString* autoDir = [publishDirectory stringByAppendingPathComponent:@"resources-auto"];
	BOOL isDirAuto;
	if ([fileManager fileExistsAtPath:autoDir isDirectory:&isDirAuto] && isDirAuto)
    {
        [result addObjectsFromArray:[fileManager contentsOfDirectoryAtPath:autoDir error:NULL]];
    }
	return result;
}

- (NSArray *)filesForResolutionDependantDirs:(NSString *)dir fileManager:(NSFileManager *)fileManager
{
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

- (void)publishSpriteSheetDir:(NSString *)spriteSheetDir sheetName:(NSString *)spriteSheetName publishDirectory:(NSString *)publishDirectory subPath:(NSString *)subPath
{
    NSDate *srcSpriteSheetDate = [self latestModifiedDateForDirectory:publishDirectory];

	[publishedSpriteSheetFiles addObject:[subPath stringByAppendingPathExtension:@"plist"]];

	BOOL isDirty = [projectSettings isDirtyRelPath:subPath];

	// Check if sprite sheet needs to be re-published
	for (NSString*resolution in publishForResolutions)
	{
		NSArray* srcDirs = [NSArray arrayWithObjects:
							[projectSettings.tempSpriteSheetCacheDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"resources-%@", resolution]],
							projectSettings.tempSpriteSheetCacheDirectory,
							nil];

		NSString* spriteSheetFile = [[spriteSheetDir stringByAppendingPathComponent:[NSString stringWithFormat:@"resources-%@", resolution]] stringByAppendingPathComponent:spriteSheetName];

		// Skip publish if sprite sheet exists and is up to date
		NSDate* dstDate = [CCBFileUtil modificationDateForFile:[spriteSheetFile stringByAppendingPathExtension:@"plist"]];
		if (dstDate && [dstDate isEqualToDate:srcSpriteSheetDate] && !isDirty)
		{
			continue;
		}

        PublishSpriteSheetOperation *operation = [[PublishSpriteSheetOperation alloc]
                initWithAppDelegate:[AppDelegate appDelegate]
                           warnings:warnings
                    projectSettings:projectSettings];

        operation.publishDirectory = publishDirectory;
        operation.publishedPNGFiles = _publishedPNGFiles;
        operation.publishedSpriteSheetNames = publishedSpriteSheetNames;
        operation.srcSpriteSheetDate = srcSpriteSheetDate;
        operation.resolution = resolution;
        operation.srcDirs = srcDirs;
        operation.spriteSheetFile = spriteSheetFile;
        operation.subPath = subPath;
        operation.targetType = targetType;

        [operation start];
        // [_publishingQueue addOperation:operation];
	}
	
	[publishedResources addObject:[subPath stringByAppendingPathExtension:@"plist"]];
	[publishedResources addObject:[subPath stringByAppendingPathExtension:@"png"]];
}

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

// Currently only checks top level of resource directories
- (BOOL) fileExistInResourcePaths:(NSString*)fileName
{
    for (NSString* dir in projectSettings.absoluteResourcePaths)
    {
        if ([[NSFileManager defaultManager] fileExistsAtPath:[dir stringByAppendingPathComponent:fileName]])
        {
            return YES;
        }
    }
    return NO;
}

- (void) publishGeneratedFiles
{
    // Create the directory if it doesn't exist
    BOOL createdDirs = [[NSFileManager defaultManager] createDirectoryAtPath:outputDir withIntermediateDirectories:YES attributes:NULL error:NULL];
    if (!createdDirs)
    {
        [warnings addWarningWithDescription:@"Failed to create output directory %@" isFatal:YES];
        return;
    }
    
    if (targetType == kCCBPublisherTargetTypeIPhone || targetType == kCCBPublisherTargetTypeAndroid)
    {
        // Generate main.js file
        
        if (projectSettings.javascriptBased
            && projectSettings.javascriptMainCCB && ![projectSettings.javascriptMainCCB isEqualToString:@""]
            && ![self fileExistInResourcePaths:@"main.js"])
        {
            // Find all jsFiles
            NSArray* jsFiles = [CCBFileUtil filesInResourcePathsWithExtension:@"js"];
            NSString* mainFile = [outputDir stringByAppendingPathComponent:@"main.js"];
            
            // Generate file from template
            CCBPublisherTemplate* tmpl = [CCBPublisherTemplate templateWithFile:@"main-jsb.txt"];
            [tmpl setStrings:jsFiles forMarker:@"REQUIRED_FILES" prefix:@"require(\"" suffix:@"\");\n"];
            [tmpl setString:projectSettings.javascriptMainCCB forMarker:@"MAIN_SCENE"];
            
            [tmpl writeToFile:mainFile];
        }
    }
    else if (targetType == kCCBPublisherTargetTypeHTML5)
    {
        // Generate index.html file
        
        NSString* indexFile = [outputDir stringByAppendingPathComponent:@"index.html"];
        
        CCBPublisherTemplate* tmpl = [CCBPublisherTemplate templateWithFile:@"index-html5.txt"];
        [tmpl setString:[NSString stringWithFormat:@"%d",projectSettings.publishResolutionHTML5_width] forMarker:@"WIDTH"];
        [tmpl setString:[NSString stringWithFormat:@"%d",projectSettings.publishResolutionHTML5_height] forMarker:@"HEIGHT"];
        
        [tmpl writeToFile:indexFile];
        
        // Generate boot-html5.js file
        
        NSString* bootFile = [outputDir stringByAppendingPathComponent:@"boot-html5.js"];
        NSArray* jsFiles = [CCBFileUtil filesInResourcePathsWithExtension:@"js"];
        
        tmpl = [CCBPublisherTemplate templateWithFile:@"boot-html5.txt"];
        [tmpl setStrings:jsFiles forMarker:@"REQUIRED_FILES" prefix:@"    '" suffix:@"',\n"];
        
        [tmpl writeToFile:bootFile];
        
        // Generate boot2-html5.js file
        
        NSString* boot2File = [outputDir stringByAppendingPathComponent:@"boot2-html5.js"];
        
        tmpl = [CCBPublisherTemplate templateWithFile:@"boot2-html5.txt"];
        [tmpl setString:projectSettings.javascriptMainCCB forMarker:@"MAIN_SCENE"];
        [tmpl setString:[NSString stringWithFormat:@"%d", projectSettings.publishResolutionHTML5_scale] forMarker:@"RESOLUTION_SCALE"];
        
        [tmpl writeToFile:boot2File];
        
        // Generate main.js file
        
        NSString* mainFile = [outputDir stringByAppendingPathComponent:@"main.js"];
        
        tmpl = [CCBPublisherTemplate templateWithFile:@"main-html5.txt"];
        [tmpl writeToFile:mainFile];
        
        // Generate resources-html5.js file
        
        NSString* resourceListFile = [outputDir stringByAppendingPathComponent:@"resources-html5.js"];
        
        NSString* resourceListStr = @"var ccb_resources = [\n";
        int resCount = 0;
        for (NSString* res in publishedResources)
        {
            NSString* comma = @",";
            if (resCount == [publishedResources count] -1) comma = @"";
            
            NSString* ext = [[res pathExtension] lowercaseString];
            
            NSString* type = NULL;
            
            if ([ext isEqualToString:@"plist"]) type = @"plist";
            else if ([ext isEqualToString:@"png"]) type = @"image";
            else if ([ext isEqualToString:@"jpg"]) type = @"image";
            else if ([ext isEqualToString:@"jpeg"]) type = @"image";
            else if ([ext isEqualToString:@"mp3"]) type = @"sound";
            else if ([ext isEqualToString:@"ccbi"]) type = @"ccbi";
            else if ([ext isEqualToString:@"fnt"]) type = @"fnt";
            
            if (type)
            {
                resourceListStr = [resourceListStr stringByAppendingFormat:@"    {type:'%@', src:\"%@\"}%@\n", type, res, comma];
            }
        }
        
        resourceListStr = [resourceListStr stringByAppendingString:@"];\n"];
        
        [resourceListStr writeToFile:resourceListFile atomically:YES encoding:NSUTF8StringEncoding error:NULL];
        
        // Copy cocos2d.min.js file
        NSString* cocos2dlibFile = [outputDir stringByAppendingPathComponent:@"cocos2d-html5.min.js"];
        NSString* cocos2dlibFileSrc = [[NSBundle mainBundle] pathForResource:@"cocos2d.min.txt" ofType:@"" inDirectory:@"publishTemplates"];
        [[NSFileManager defaultManager] copyItemAtPath: cocos2dlibFileSrc toPath:cocos2dlibFile error:NULL];
    }
    
    // Generate file lookup
    NSMutableDictionary* fileLookup = [NSMutableDictionary dictionary];
    
    NSMutableDictionary* metadata = [NSMutableDictionary dictionary];
    [metadata setObject:[NSNumber numberWithInt:1] forKey:@"version"];
    
    [fileLookup setObject:metadata forKey:@"metadata"];
    [fileLookup setObject:renamedFiles forKey:@"filenames"];
    
    NSString* lookupFile = [outputDir stringByAppendingPathComponent:@"fileLookup.plist"];
    
    [fileLookup writeToFile:lookupFile atomically:YES];
    
    // Generate sprite sheet lookup
    NSMutableDictionary* spriteSheetLookup = [NSMutableDictionary dictionary];
    
    metadata = [NSMutableDictionary dictionary];
    [metadata setObject:[NSNumber numberWithInt:1] forKey:@"version"];
    
    [spriteSheetLookup setObject:metadata forKey:@"metadata"];
    
    [spriteSheetLookup setObject:[publishedSpriteSheetFiles allObjects] forKey:@"spriteFrameFiles"];
    
    NSString* spriteSheetLookupFile = [outputDir stringByAppendingPathComponent:@"spriteFrameFileList.plist"];
    
    [spriteSheetLookup writeToFile:spriteSheetLookupFile atomically:YES];
    
    // Generate Cocos2d setup file
    NSMutableDictionary* configCocos2d = [NSMutableDictionary dictionary];
    
    NSString* screenMode = @"";
    if (projectSettings.designTarget == kCCBDesignTargetFixed)
		screenMode = @"CCScreenModeFixed";
    else if (projectSettings.designTarget == kCCBDesignTargetFlexible)
		screenMode = @"CCScreenModeFlexible";
    [configCocos2d setObject:screenMode forKey:@"CCSetupScreenMode"];

	NSString *screenOrientation = @"";
	if (projectSettings.defaultOrientation == kCCBOrientationLandscape)
	{
		screenOrientation = @"CCScreenOrientationLandscape";
	}
	else if (projectSettings.defaultOrientation == kCCBOrientationPortrait)
	{
		screenOrientation = @"CCScreenOrientationPortrait";
	}

	[configCocos2d setObject:screenOrientation forKey:@"CCSetupScreenOrientation"];

	[configCocos2d setObject:[NSNumber numberWithBool:YES] forKey:@"CCSetupTabletScale2X"];

	NSString *configCocos2dFile = [outputDir stringByAppendingPathComponent:@"configCocos2d.plist"];
	[configCocos2d writeToFile:configCocos2dFile atomically:YES];
}

- (BOOL) publishAllToDirectory:(NSString*)dir
{
    outputDir = dir;
    
    publishedResources = [NSMutableSet set];
    renamedFiles = [NSMutableDictionary dictionary];

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

- (BOOL) archiveToFile:(NSString*)file
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

- (void) addWarningWithDescription:(NSString*)description isFatal:(BOOL)fatal relatedFile:(NSString*) relatedFile resolution:(NSString*) resolution
{
    [warnings addWarningWithDescription:description isFatal:fatal relatedFile:(relatedFile == nil? currentWorkingFile : relatedFile) resolution:resolution];
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

        if (![self archiveToFile:zipFile])
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

    [self connfigureResolutionsForIOS];

    NSString *publishDir = [projectSettings.publishDirectory absolutePathFromBaseDirPath:[projectSettings.projectPath stringByDeletingLastPathComponent]];

    if (projectSettings.publishToZipFile)
    {
        // Publish archive
        NSString *zipFile = [publishDir stringByAppendingPathComponent:@"ccb.zip"];

        if (![self archiveToFile:zipFile])
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

    // Add iPhone resolutions from publishing settings
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

- (void) publishAsync
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

        [_publishingQueue setSuspended:NO];

        [self postProcessPublishedPNGFilesWithOptiPNG];

        [_publishingQueue waitUntilAllOperationsAreFinished];

		[self flagFilesWithWarningsAsDirty];

		NSLog(@"[PUBLISH] Done in %.2f seconds.",  [[NSDate date] timeIntervalSince1970] - startTime);

        dispatch_sync(dispatch_get_main_queue(), ^
        {
            [[AppDelegate appDelegate] publisher:self finishedWithWarnings:warnings];
        });
    });
}

- (void)postProcessPublishedPNGFilesWithOptiPNG
{
    if (projectSettings.publishEnvironment == PublishEnvironmentDevelop)
    {
        return;
    }

    NSString *pathToOptiPNG = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"optipng"];

    if (!pathToOptiPNG)
    {
        NSLog(@"ERROR: optipng was not found.");
        return;
    }

    for (NSString *pngFile in _publishedPNGFiles)
    {
        OptimizeImageWithOptiPNGOperation *operation = [[OptimizeImageWithOptiPNGOperation alloc]
                initWithFilePath:pngFile
                     optiPngPath:pathToOptiPNG
                        warnings:warnings
                     appDelegate:[AppDelegate appDelegate]];

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

- (void) publish
{
    [self doPublish];

	[self flagFilesWithWarningsAsDirty];

    [[AppDelegate appDelegate] publisher:self finishedWithWarnings:warnings];
}

+ (void) cleanAllCacheDirectoriesWithProjectSettings:(ProjectSettings *)projectSettings
{
    NSAssert(projectSettings != nil, @"Project settings should not be nil.");

    projectSettings.needRepublish = YES;
    [projectSettings store];

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString* ccbChacheDir = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"com.cocosbuilder.CocosBuilder"];
    [[NSFileManager defaultManager] removeItemAtPath:ccbChacheDir error:NULL];
}

@end