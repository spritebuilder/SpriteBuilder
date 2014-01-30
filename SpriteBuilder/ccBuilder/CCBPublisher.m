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

@implementation CCBPublisher

@synthesize publishFormat;
@synthesize runAfterPublishing;
@synthesize browser;

- (id) initWithProjectSettings:(ProjectSettings*)settings warnings:(CCBWarnings*)w
{
    self = [super init];
    if (!self) return NULL;
    
    // Save settings and warning log
    projectSettings = settings;
    warnings = w;
    
    // Setup extensions to copy
    copyExtensions = [[NSArray alloc] initWithObjects:@"jpg", @"png", @"psd", @"pvr", @"ccz", @"plist", @"fnt", @"ttf",@"js", @"json", @"wav",@"mp3",@"m4a",@"caf",@"ccblang", nil];
    
    publishedSpriteSheetNames = [[NSMutableArray alloc] init];
    publishedSpriteSheetFiles = [[NSMutableSet alloc] init];
    
    // Set format to use for exports
    self.publishFormat = projectSettings.exporter;
    
    return self;
}

- (NSDate*) latestModifiedDateForDirectory:(NSString*) dir
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

- (BOOL) publishCCBFile:(NSString*)srcFile to:(NSString*)dstFile
{
    PlugInExport* plugIn = [[PlugInManager sharedManager] plugInExportForExtension:publishFormat];
    if (!plugIn)
    {
        [warnings addWarningWithDescription:[NSString stringWithFormat: @"Plug-in is missing for publishing files to %@-format. You can select plug-in in Project Settings.",publishFormat] isFatal:YES];
        return NO;
    }
    
    // Load src file
    NSMutableDictionary* doc = [NSMutableDictionary dictionaryWithContentsOfFile:srcFile];
    if (!doc)
    {
        [warnings addWarningWithDescription:[NSString stringWithFormat:@"Failed to publish ccb-file. File is in invalid format: %@",srcFile] isFatal:NO];
        return YES;
    }
    
    // Export file
    plugIn.flattenPaths = projectSettings.flattenPaths;
    plugIn.projectSettings = projectSettings;
    NSData* data = [plugIn exportDocument:doc];
    if (!data)
    {
        [warnings addWarningWithDescription:[NSString stringWithFormat:@"Failed to publish ccb-file: %@",srcFile] isFatal:NO];
        return YES;
    }
    
    // Save file
    BOOL success = [data writeToFile:dstFile atomically:YES];
    if (!success)
    {
        [warnings addWarningWithDescription:[NSString stringWithFormat:@"Failed to publish ccb-file. Failed to write file: %@",dstFile] isFatal:NO];
        return YES;
    }
    
    return YES;
}

- (BOOL) publishImageFile:(NSString*)srcFile to:(NSString*)dstFile isSpriteSheet:(BOOL)isSpriteSheet outDir:(NSString*) outDir
{
    for (NSString* resolution in publishForResolutions)
    {
        if (![self publishImageFile:srcFile to:dstFile isSpriteSheet:isSpriteSheet outDir:outDir resolution:resolution]) return NO;
    }
    
    return YES;
}

- (BOOL) publishImageFile:(NSString*)srcPath to:(NSString*)dstPath isSpriteSheet:(BOOL)isSpriteSheet outDir:(NSString*) outDir resolution:(NSString*) resolution
{
    AppDelegate* ad = [AppDelegate appDelegate];
    
    NSString* relPath = [ResourceManagerUtil relativePathFromAbsolutePath:srcPath];
    
    // Skip already published sprite sheet
    if (isSpriteSheet)
    {
        NSString* ssDir = [srcPath stringByDeletingLastPathComponent];
        NSString* ssDirRel = [ResourceManagerUtil relativePathFromAbsolutePath:ssDir];
        NSString* ssName = [ssDir lastPathComponent];
        
        // Get modified date of sprite sheet src
        NSDate* srcDate = [self latestModifiedDateForDirectory:ssDir];
        BOOL isDirty = [projectSettings isDirtyRelPath:ssDirRel];
        
        // Make the name for the final sprite sheet
        NSString* ssDstPath = [[[[outDir stringByDeletingLastPathComponent] stringByAppendingPathComponent:[NSString stringWithFormat:@"resources-%@", resolution]] stringByAppendingPathComponent:ssName] stringByAppendingPathExtension:@"plist"];
        
        NSDate* ssDstDate = [CCBFileUtil modificationDateForFile:ssDstPath];
        
        if (ssDstDate && [ssDstDate isEqualToDate:srcDate] && !isDirty)
        {
            return YES;
        }
    }
    {
        // Add the file name to published resource list
        [publishedResources addObject:relPath];
    }
    
    // Update progress
    [ad modalStatusWindowUpdateStatusText:[NSString stringWithFormat:@"Publishing %@...", [dstPath lastPathComponent]]];
    
    // Find out which file to copy for the current resolution
    NSFileManager* fm = [NSFileManager defaultManager];
    
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
    
    // Create destination directory if it doesn't exist
    [fm createDirectoryAtPath:dstDir withIntermediateDirectories:YES attributes:NULL error:NULL];
    
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
    
    if ([fm fileExistsAtPath:srcPath])
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
        [fm copyItemAtPath:srcPath toPath:dstPath error:NULL];
        
        // Convert it
        NSString* dstPathConverted = [[FCFormatConverter defaultConverter] convertImageAtPath:dstPath format:format dither:dither compress:compress isSpriteSheet:isSpriteSheet];
        
        // Update modification date
        [CCBFileUtil setModificationDate:srcDate forFile:dstPathConverted];
        
        return YES;
    }
    else if ([fm fileExistsAtPath:srcAutoPath])
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
        NSString* dstPathConverted = [[FCFormatConverter defaultConverter] convertImageAtPath:dstPath format:format dither:dither compress:compress isSpriteSheet:isSpriteSheet];
        
        // Update modification date
        [CCBFileUtil setModificationDate:srcDate forFile:dstPathConverted];
        
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

- (BOOL) publishSoundFile:(NSString*) srcPath to:(NSString*) dstPath
{
    NSString* relPath = [ResourceManagerUtil relativePathFromAbsolutePath:srcPath];
    
    int format = 0;
    int quality = 0;
    
    if (targetType == kCCBPublisherTargetTypeIPhone)
    {
        int formatRaw = [[projectSettings valueForRelPath:relPath andKey:@"format_ios_sound"] intValue];
        quality = [[projectSettings valueForRelPath:relPath andKey:@"format_ios_sound_quality"] intValue];
        if (!quality) quality = projectSettings.publishAudioQuality_ios;
        
        if (formatRaw == 0) format = kFCSoundFormatCAF;
        else if (formatRaw == 1) format = kFCSoundFormatMP4;
        else
        {
            [warnings addWarningWithDescription:[NSString stringWithFormat:@"Invalid sound conversion format for %@", relPath] isFatal:YES];
            return NO;
        }
    }
    else if (targetType == kCCBPublisherTargetTypeAndroid)
    {
        int formatRaw = [[projectSettings valueForRelPath:relPath andKey:@"format_android_sound"] intValue];
        quality = [[projectSettings valueForRelPath:relPath andKey:@"format_android_sound_quality"] intValue];
        if (!quality) quality = projectSettings.publishAudioQuality_android;
        
        if (formatRaw == 0) format = kFCSoundFormatOGG;
        else
        {
            [warnings addWarningWithDescription:[NSString stringWithFormat:@"Invalid sound conversion format for %@", relPath] isFatal:YES];
            return NO;
        }
    }
    
    NSFileManager* fm = [NSFileManager defaultManager];
    
    NSString* dstPathConverted = [[FCFormatConverter defaultConverter] proposedNameForConvertedSoundAtPath:dstPath format:format quality:quality];
    BOOL isDirty = [projectSettings isDirtyRelPath:relPath];
    
    [self addRenamingRuleFrom:relPath to:[[FCFormatConverter defaultConverter] proposedNameForConvertedSoundAtPath:relPath format:format quality:quality]];
    
    if ([fm fileExistsAtPath:dstPathConverted] && [[CCBFileUtil modificationDateForFile:srcPath] isEqualToDate:[CCBFileUtil modificationDateForFile:dstPathConverted]] && !isDirty)
    {
        // Skip files that are already converted
        return YES;
    }
    
    // Copy file
    [fm copyItemAtPath:srcPath toPath:dstPath error:NULL];
    
    // Convert file
    dstPathConverted = [[FCFormatConverter defaultConverter] convertSoundAtPath:dstPath format:format quality:quality];
    
    if (!dstPathConverted)
    {
        [warnings addWarningWithDescription:[NSString stringWithFormat:@"Failed to convert audio file %@", relPath] isFatal:NO];
        return YES;
    }
    
    // Update modification date
    [CCBFileUtil setModificationDate:[CCBFileUtil modificationDateForFile:srcPath] forFile:dstPathConverted];
    
    return YES;
}

- (BOOL) publishRegularFile:(NSString*) srcPath to:(NSString*) dstPath
{
    // Check if file already exists
    if ([[NSFileManager defaultManager] fileExistsAtPath:dstPath] &&
        [[CCBFileUtil modificationDateForFile:srcPath] isEqualToDate:[CCBFileUtil modificationDateForFile:dstPath]])
    {
        return YES;
    }
    
    // Copy file and make sure modification date is the same as for src file
    [[NSFileManager defaultManager] removeItemAtPath:dstPath error:NULL];
    [[NSFileManager defaultManager] copyItemAtPath:srcPath toPath:dstPath error:NULL];
    [CCBFileUtil setModificationDate:[CCBFileUtil modificationDateForFile:srcPath] forFile:dstPath];
    
    return YES;
}

- (BOOL) publishDirectory:(NSString*) dir subPath:(NSString*) subPath
{
    AppDelegate* ad = [AppDelegate appDelegate];
    NSArray* resIndependentDirs = [ResourceManager resIndependentDirs];
    
    NSFileManager* fm = [NSFileManager defaultManager];
    
    // Path to output directory for the currently exported path
    NSString* outDir = NULL;
    if (projectSettings.flattenPaths && projectSettings.publishToZipFile)
    {
        outDir = outputDir;
    }
    else
    {
        outDir = [outputDir stringByAppendingPathComponent:subPath];
    }
    
    // Check for generated sprite sheets
    BOOL isGeneratedSpriteSheet = NO;
    NSDate* srcSpriteSheetDate = NULL;
    
    if ([[projectSettings valueForRelPath:subPath andKey:@"isSmartSpriteSheet"] boolValue])
    {
        isGeneratedSpriteSheet = YES;
        srcSpriteSheetDate = [self latestModifiedDateForDirectory:dir];
        
        // Clear temporary sprite sheet directory
        [fm removeItemAtPath:[projectSettings tempSpriteSheetCacheDirectory] error:NULL];
    }
    
    // Create the directory if it doesn't exist
    if (!isGeneratedSpriteSheet)
    {
        BOOL createdDirs = [fm createDirectoryAtPath:outDir withIntermediateDirectories:YES attributes:NULL error:NULL];
        if (!createdDirs)
        {
            [warnings addWarningWithDescription:@"Failed to create output directory %@" isFatal:YES];
            return NO;
        }
    }
    
    // Add files from main directory
    NSMutableSet* files = [NSMutableSet setWithArray:[fm contentsOfDirectoryAtPath:dir error:NULL]];
    
    // Add files from resolution depentant directories
    for (NSString* publishExt in publishForResolutions)
    {
        NSString* resolutionDir = [dir stringByAppendingPathComponent:publishExt];
        BOOL isDirectory;
        if ([fm fileExistsAtPath:resolutionDir isDirectory:&isDirectory] && isDirectory)
        {
            [files addObjectsFromArray:[fm contentsOfDirectoryAtPath:resolutionDir error:NULL]];
        }
    }
    
    // Add files from the -auto directory
    NSString* autoDir = [dir stringByAppendingPathComponent:@"resources-auto"];
    BOOL isDirAuto;
    if ([fm fileExistsAtPath:autoDir isDirectory:&isDirAuto] && isDirAuto)
    {
        [files addObjectsFromArray:[fm contentsOfDirectoryAtPath:autoDir error:NULL]];
    }
    
    // Iterate through all files
    for (NSString* fileName in files)
    {
        if ([fileName hasPrefix:@"."]) continue;
        
        NSString* filePath = [dir stringByAppendingPathComponent:fileName];
        
        BOOL isDirectory;
        BOOL fileExists = [fm fileExistsAtPath:filePath isDirectory:&isDirectory];
        if (fileExists && isDirectory)
        {
            if ([[filePath pathExtension] isEqualToString:@"bmfont"])
            {
                // This is a bitmap font, just copy it
                [self publishRegularFile:filePath to:[outDir stringByAppendingPathComponent:fileName]];
                continue;
            }
            
            // This is a directory
            
            NSString* childPath = NULL;
            if (subPath) childPath = [NSString stringWithFormat:@"%@/%@", subPath, fileName];
            else childPath = fileName;
            
            // Skip resource independent directories
            if ([resIndependentDirs containsObject:fileName]) continue;
            
            // Skip directories in generated sprite sheets
            if (isGeneratedSpriteSheet)
            {
                [warnings addWarningWithDescription:[NSString stringWithFormat:@"Generated sprite sheets do not support directories (%@)", [fileName lastPathComponent]] isFatal:NO relatedFile:subPath];
                continue;
            }
            
            // Skip the empty folder
            if ([[fm contentsOfDirectoryAtPath:filePath error:NULL] count] == 0)  continue;
            
            // Skip the fold no .ccb files when onlyPublishCCBs is true
            if(projectSettings.onlyPublishCCBs && ![self containsCCBFile:filePath]) continue;
            
            [self publishDirectory:filePath subPath:childPath];
        }
        else
        {
            // This is a file
            
            NSString* ext = [[fileName pathExtension] lowercaseString];
            
            // Skip non png files for generated sprite sheets
            if (isGeneratedSpriteSheet && !([ext isEqualToString:@"png"] || [ext isEqualToString:@"psd"]))
            {
                [warnings addWarningWithDescription:[NSString stringWithFormat:@"Non-png file in smart sprite sheet (%@)", [fileName lastPathComponent]] isFatal:NO relatedFile:subPath];
                continue;
            }
            
            if ([copyExtensions containsObject:ext] && !projectSettings.onlyPublishCCBs)
            {
                // This file and should be copied
                
                // Get destination file name
                NSString* dstFile = [outDir stringByAppendingPathComponent:fileName];
                
                // Use temp cache directory for generated sprite sheets
                if (isGeneratedSpriteSheet)
                {
                    dstFile = [[projectSettings tempSpriteSheetCacheDirectory] stringByAppendingPathComponent:fileName];
                }
                
                // Copy file (and possibly convert)
                if ([ext isEqualToString:@"png"] || [ext isEqualToString:@"psd"])
                {
                    // Publish images
                    [self publishImageFile:filePath to:dstFile isSpriteSheet:isGeneratedSpriteSheet outDir:outDir];
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
                // This is a ccb-file and should be published
                
                NSString* strippedFileName = [fileName stringByDeletingPathExtension];
                
                NSString* dstFile = [[outDir stringByAppendingPathComponent:strippedFileName] stringByAppendingPathExtension:publishFormat];
                
                // Add file to list of published files
                NSString* localFileName = [dstFile relativePathFromBaseDirPath:outputDir];
                [publishedResources addObject:localFileName];
                
                if ([dstFile isEqualToString:filePath])
                {
                    [warnings addWarningWithDescription:@"Publish will overwrite files in resource directory." isFatal:YES];
                    return NO;
                }
                
                NSDate* srcDate = [CCBFileUtil modificationDateForFile:filePath];
                NSDate* dstDate = [CCBFileUtil modificationDateForFile:dstFile];
                
                if (![srcDate isEqualToDate:dstDate])
                {
                    [ad modalStatusWindowUpdateStatusText:[NSString stringWithFormat:@"Publishing %@...", fileName]];
                    
                    // Remove old file
                    [fm removeItemAtPath:dstFile error:NULL];
                    
                    // Copy the file
                    BOOL sucess = [self publishCCBFile:filePath to:dstFile];
                    if (!sucess) return NO;
                    
                    [CCBFileUtil setModificationDate:srcDate forFile:dstFile];
                }
            }
        }
    }
    
    if (isGeneratedSpriteSheet)
    {
        // Sprite files should have been saved to the temp cache directory, now actually generate the sprite sheets
        NSString* spriteSheetDir = [outDir stringByDeletingLastPathComponent];
        NSString* spriteSheetName = [outDir lastPathComponent];
        
        [publishedSpriteSheetFiles addObject:[subPath stringByAppendingPathExtension:@"plist"]];
        
        // Load settings
        BOOL isDirty = [projectSettings isDirtyRelPath:subPath];
        int format_ios = [[projectSettings valueForRelPath:subPath andKey:@"format_ios"] intValue];
        BOOL format_ios_dither = [[projectSettings valueForRelPath:subPath andKey:@"format_ios_dither"] boolValue];
        BOOL format_ios_compress= [[projectSettings valueForRelPath:subPath andKey:@"format_ios_compress"] boolValue];
        int format_android = [[projectSettings valueForRelPath:subPath andKey:@"format_android"] intValue];
        BOOL format_android_dither = [[projectSettings valueForRelPath:subPath andKey:@"format_android_dither"] boolValue];
        BOOL format_android_compress= [[projectSettings valueForRelPath:subPath andKey:@"format_android_compress"] boolValue];

        // Check if sprite sheet needs to be re-published
        for (NSString* res in publishForResolutions)
        {
            NSArray* srcDirs = [NSArray arrayWithObjects:
                                [projectSettings.tempSpriteSheetCacheDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"resources-%@", res]],
                                projectSettings.tempSpriteSheetCacheDirectory,
                                nil];
            
            NSString* spriteSheetFile = spriteSheetFile = [[spriteSheetDir stringByAppendingPathComponent:[NSString stringWithFormat:@"resources-%@", res]] stringByAppendingPathComponent:spriteSheetName];
            
            // Skip publish if sprite sheet exists and is up to date
            NSDate* dstDate = [CCBFileUtil modificationDateForFile:[spriteSheetFile stringByAppendingPathExtension:@"plist"]];
            if (dstDate && [dstDate isEqualToDate:srcSpriteSheetDate] && !isDirty)
            {
                continue;
            }
            
            // Check if preview should be generated
            NSString* previewFilePath = NULL;
            if (![publishedSpriteSheetNames containsObject:subPath])
            {
                previewFilePath = [dir stringByAppendingPathExtension:@"ppng"];
                [publishedSpriteSheetNames addObject:subPath];
            }
            
            // Generate sprite sheet
            Tupac* packer = [Tupac tupac];
            packer.outputName = spriteSheetFile;
            packer.outputFormat = TupacOutputFormatCocos2D;
            packer.previewFile = previewFilePath;
            
            // Set image format
            if (targetType == kCCBPublisherTargetTypeIPhone)
            {
                packer.imageFormat = format_ios;
                packer.compress = format_ios_compress;
                packer.dither = format_ios_dither;
            }
            else if (targetType == kCCBPublisherTargetTypeAndroid)
            {
                packer.imageFormat = format_android;
                packer.compress = format_android_compress;
                packer.dither = format_android_dither;
            }
            /*
            else if (targetType == kCCBPublisherTargetTypeHTML5)
            {
                packer.imageFormat = ssSettings.textureFileFormatHTML5;
                packer.compress = NO;
                packer.dither = ssSettings.ditherHTML5;
            }
             */
            
            // Set texture maximum size
            if ([res isEqualToString:@"phone"]) packer.maxTextureSize = 1024;
            else if ([res isEqualToString:@"phonehd"]) packer.maxTextureSize = 2048;
            else if ([res isEqualToString:@"tablet"]) packer.maxTextureSize = 2048;
            else if ([res isEqualToString:@"tablethd"]) packer.maxTextureSize = 4096;
            
            // Update progress
            [ad modalStatusWindowUpdateStatusText:[NSString stringWithFormat:@"Generating sprite sheet %@...", [[subPath stringByAppendingPathExtension:@"plist"] lastPathComponent]]];
            
            // Pack texture
            packer.directoryPrefix = subPath;
            packer.border = YES;
            [packer createTextureAtlasFromDirectoryPaths:srcDirs];
            
            if (packer.errorMessage)
            {
                [warnings addWarningWithDescription:packer.errorMessage isFatal:NO relatedFile:subPath resolution:res];
            }
            
            // Set correct modification date
            [CCBFileUtil setModificationDate:srcSpriteSheetDate forFile:[spriteSheetFile stringByAppendingPathExtension:@"plist"]];
        }
        
        [publishedResources addObject:[subPath stringByAppendingPathExtension:@"plist"]];
        [publishedResources addObject:[subPath stringByAppendingPathExtension:@"png"]];
    }
    
    return YES;
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
    
    NSString* screenOrientation = @"";
    if (projectSettings.defaultOrientation == kCCBOrientationLandscape)
		screenOrientation = @"CCScreenOrientationLandscape";
    else if (projectSettings.defaultOrientation == kCCBOrientationPortrait)
		screenOrientation = @"CCScreenOrientationPortrait";
    [configCocos2d setObject:screenOrientation forKey:@"CCSetupScreenOrientation"];
    
    [configCocos2d setObject:[NSNumber numberWithBool:YES] forKey:@"CCSetupTabletScale2X"];
    
    NSString* configCocos2dFile = [outputDir stringByAppendingPathComponent:@"configCocos2d.plist"];
    [configCocos2d writeToFile:configCocos2dFile atomically:YES];
}

- (BOOL) publishAllToDirectory:(NSString*)dir
{
    outputDir = dir;
    
    publishedResources = [NSMutableSet set];
    renamedFiles = [NSMutableDictionary dictionary];
    
    // Setup paths for automatically generated sprite sheets
    generatedSpriteSheetDirs = [projectSettings smartSpriteSheetDirectories];
    
    // Publish resources and ccb-files
    for (NSString* dir in projectSettings.absoluteResourcePaths)
    {
        if (![self publishDirectory:dir subPath:NULL]) return NO;
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

- (BOOL) publish_
{
    // Remove all old publish directories if user has cleaned the cache
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
    
    if (!runAfterPublishing)
    {
        // Normal publishing
        
        // iOS
        if (projectSettings.publishEnablediPhone)
        {
            targetType = kCCBPublisherTargetTypeIPhone;
            warnings.currentTargetType = targetType;
            
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
            
            NSString* publishDir = [projectSettings.publishDirectory absolutePathFromBaseDirPath:[projectSettings.projectPath stringByDeletingLastPathComponent]];
            
            if (projectSettings.publishToZipFile)
            {
                // Publish archive
                NSString *zipFile = [publishDir stringByAppendingPathComponent:@"ccb.zip"];
                
                if (![self archiveToFile:zipFile]) return NO;
            } else
            {
                // Publish files
                if (![self publishAllToDirectory:publishDir]) return NO;
            }
        }
        
        // Android
        if (projectSettings.publishEnabledAndroid)
        {
            targetType = kCCBPublisherTargetTypeAndroid;
            warnings.currentTargetType = targetType;
            
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
            
            NSString* publishDir = [projectSettings.publishDirectoryAndroid absolutePathFromBaseDirPath:[projectSettings.projectPath stringByDeletingLastPathComponent]];
            
            if (projectSettings.publishToZipFile)
            {
                // Publish archive
                NSString *zipFile = [publishDir stringByAppendingPathComponent:@"ccb.zip"];
                
                if (![self archiveToFile:zipFile]) return NO;
            } else
            {
                // Publish files
                if (![self publishAllToDirectory:publishDir]) return NO;
            }
        }
        
        /*
        // HTML 5
        if (projectSettings.publishEnabledHTML5)
        {
            targetType = kCCBPublisherTargetTypeHTML5;
            
            NSMutableArray* resolutions = [NSMutableArray array];
            [resolutions addObject: @"html5"];
            publishForResolutions = resolutions;
            
            publishToSingleResolution = YES;
            
            NSString* publishDir = [projectSettings.publishDirectoryHTML5 absolutePathFromBaseDirPath:[projectSettings.projectPath stringByDeletingLastPathComponent]];
            
            if (projectSettings.publishToZipFile)
            {
                // Publish archive
                NSString *zipFile = [publishDir stringByAppendingPathComponent:@"ccb.zip"];
                
                if (![self publishAllToDirectory:projectSettings.publishCacheDirectory] || ![self archiveToFile:zipFile]) return NO;
            } else
            {
                // Publish files
                if (![self publishAllToDirectory:publishDir]) return NO;
            }
        }
         */
        
    }
    else
    {
        // Publishing to device no longer supported
    }
    
    // Once published, set needRepublish back to NO
    [projectSettings clearAllDirtyMarkers];
    if (projectSettings.needRepublish)
    {
        projectSettings.needRepublish = NO;
        [projectSettings store];
    }
    
    return YES;
}

- (void) publish
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        
        // Do actual publish
        [self publish_];
        
        // Flag files with warnings as dirty
        for (CCBWarning* warning in warnings.warnings)
        {
            if (warning.relatedFile)
            {
                [projectSettings markAsDirtyRelPath:warning.relatedFile];
            }
        }
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            AppDelegate* ad = [AppDelegate appDelegate];
            [ad publisher:self finishedWithWarnings:warnings];
        });
    });
    
}

+ (void) cleanAllCacheDirectories
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString* ccbChacheDir = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"com.cocosbuilder.CocosBuilder"];
    [[NSFileManager defaultManager] removeItemAtPath:ccbChacheDir error:NULL];
}


@end
