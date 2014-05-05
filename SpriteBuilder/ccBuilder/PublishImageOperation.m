#import "PublishImageOperation.h"

#import "FCFormatConverter.h"
#import "CCBFileUtil.h"
#import "ResourceManager.h"
#import "AppDelegate.h"
#import "ResourceManagerUtil.h"
#import "CCBWarnings.h"
#import "DateCache.h"
#import "CCBPublisher.h"
#import "NSString+Publishing.h"
#import "PublishFileLookup.h"


@interface PublishImageOperation ()

@property (nonatomic, strong) FCFormatConverter *formatConverter;

@end

@implementation PublishImageOperation

- (void)main
{
    NSLog(@"[%@] %@", [self class], [_srcPath lastPathComponent]);

    [self publishImage];

    [_publisher operationFinishedTick];
}

- (void)publishImage
{
    // TODO: this is a long method -> split up!
    NSString *relPath = [ResourceManagerUtil relativePathFromAbsolutePath:_srcPath];

    if (_isSpriteSheet
        && [self isSpriteSheetAlreadyPublished:_srcPath outDir:_outDir resolution:_resolution])
    {
        return;
    }

    [_publishedResources addObject:relPath];

    [[AppDelegate appDelegate] modalStatusWindowUpdateStatusText:[NSString stringWithFormat:@"Publishing %@...", [_dstPath lastPathComponent]]];

    // Find out which file to copy for the current resolution
    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSString *srcFileName = [_srcPath lastPathComponent];
    NSString *dstFileName = [_dstPath lastPathComponent];
    NSString *srcDir = [_srcPath stringByDeletingLastPathComponent];
    NSString *dstDir = [_dstPath stringByDeletingLastPathComponent];
    NSString *srcAutoPath = [_srcPath resourceAutoFilePath];

    // Update path to reflect resolution
    srcDir = [srcDir stringByAppendingPathComponent:[@"resources-" stringByAppendingString:_resolution]];
    dstDir = [dstDir stringByAppendingPathComponent:[@"resources-" stringByAppendingString:_resolution]];

    self.srcPath = [srcDir stringByAppendingPathComponent:srcFileName];
    self.dstPath = [dstDir stringByAppendingPathComponent:dstFileName];

    // Sprite Kit requires specific extensions for specific image resolutions (ie @2x, ~ipad, ..)
    if (_projectSettings.engine == CCBTargetEngineSpriteKit)
    {
        self.dstPath = [self pathWithCocoaImageResolutionSuffix:_dstPath resolution:_resolution];
    }

    // Create destination directory if it doesn't exist
    [fileManager createDirectoryAtPath:dstDir withIntermediateDirectories:YES attributes:NULL error:NULL];

    // Get the format of the published image
    int format = kFCImageFormatPNG;
    BOOL dither = NO;
    BOOL compress = NO;

    // TODO: Move to data object: format, dither, compress
    if (!_isSpriteSheet)
    {
        if (_targetType == kCCBPublisherTargetTypeIPhone)
        {
            format = [[_projectSettings valueForRelPath:relPath andKey:@"format_ios"] intValue];
            dither = [[_projectSettings valueForRelPath:relPath andKey:@"format_ios_dither"] boolValue];
            compress = [[_projectSettings valueForRelPath:relPath andKey:@"format_ios_compress"] boolValue];
        }
        else if (_targetType == kCCBPublisherTargetTypeAndroid)
        {
            format = [[_projectSettings valueForRelPath:relPath andKey:@"format_android"] intValue];
            dither = [[_projectSettings valueForRelPath:relPath andKey:@"format_android_dither"] boolValue];
            compress = [[_projectSettings valueForRelPath:relPath andKey:@"format_android_compress"] boolValue];
        }
    }

    // Fetch new name
    NSString *dstPathProposal = [[FCFormatConverter defaultConverter] proposedNameForConvertedImageAtPath:_dstPath
                                                                                                   format:format
                                                                                                 compress:compress
                                                                                            isSpriteSheet:_isSpriteSheet];

    // Add renaming rule
    NSString *relPathRenamed = [[FCFormatConverter defaultConverter] proposedNameForConvertedImageAtPath:relPath
                                                                                                  format:format
                                                                                                compress:compress
                                                                                           isSpriteSheet:_isSpriteSheet];

    [_fileLookup addRenamingRuleFrom:relPath to:relPathRenamed];

    // Copy and convert the image
    BOOL isDirty = [_projectSettings isDirtyRelPath:relPath];

    if ([fileManager fileExistsAtPath:_srcPath])
    {
        // Has customized file for resolution

        // Check if file already exists
        NSDate *srcDate = [CCBFileUtil modificationDateForFile:_srcPath];
        NSDate *dstDate = [CCBFileUtil modificationDateForFile:dstPathProposal];

        if (dstDate
            && [srcDate isEqualToDate:dstDate]
            && !isDirty)
        {
            return;
        }

        // Copy file
        [fileManager copyItemAtPath:_srcPath toPath:_dstPath error:NULL];

        // Convert it
        NSString *dstPathConverted = nil;
        NSError *error;

        self.formatConverter = [FCFormatConverter defaultConverter];
        if (![_formatConverter convertImageAtPath:_dstPath
                                           format:format
                                           dither:dither
                                         compress:compress
                                    isSpriteSheet:_isSpriteSheet
                                   outputFilename:&dstPathConverted
                                            error:&error])
        {
            [_warnings addWarningWithDescription:[NSString stringWithFormat:@"Failed to convert image: %@. Error Message:%@", srcFileName, error.localizedDescription]
                                         isFatal:NO];
            self.formatConverter = nil;
            return;
        }
        self.formatConverter = nil;

        // Update modification date
        [CCBFileUtil setModificationDate:srcDate forFile:dstPathConverted];

        if (!_isSpriteSheet
            && format == kFCImageFormatPNG)
        {
            [_publishedPNGFiles addObject:dstPathConverted];
        }
    }
    else if ([fileManager fileExistsAtPath:srcAutoPath])
    {
        // Use resources-auto file for conversion

        // Check if file already exist
        NSDate *srcDate = [CCBFileUtil modificationDateForFile:srcAutoPath];
        NSDate *dstDate = [CCBFileUtil modificationDateForFile:dstPathProposal];

        if (dstDate
            && [srcDate isEqualToDate:dstDate]
            && !isDirty)
        {
            return;
        }

        // Copy file and resize
        [[ResourceManager sharedManager] createCachedImageFromAuto:srcAutoPath saveAs:_dstPath forResolution:_resolution];

        // Convert it
        NSString *dstPathConverted = nil;
        NSError *error;

        self.formatConverter = [FCFormatConverter defaultConverter];
        if (![_formatConverter convertImageAtPath:_dstPath
                                           format:format
                                           dither:dither
                                         compress:compress
                                    isSpriteSheet:_isSpriteSheet
                                   outputFilename:&dstPathConverted
                                            error:&error])
        {
            [_warnings addWarningWithDescription:[NSString stringWithFormat:@"Failed to convert image: %@. Error Message:%@", srcFileName, error.localizedDescription]
                                         isFatal:NO];
        }
        self.formatConverter = nil;

        // Update modification date
        [CCBFileUtil setModificationDate:srcDate forFile:dstPathConverted];

        if (!_isSpriteSheet
            && format == kFCImageFormatPNG)
        {
            [_publishedPNGFiles addObject:dstPathConverted];
        }
    }
    else
    {
        [_warnings addWarningWithDescription:[NSString stringWithFormat:@"Failed to publish file %@, make sure it is in the resources-auto folder.", srcFileName] isFatal:NO];
    }
}

- (void)cancel
{
    NSLog(@"[%@] CANCELLED %@@%@", [self class], [_srcPath lastPathComponent], _resolution);

    [super cancel];
    [_formatConverter cancel];
}

- (BOOL)isSpriteSheetAlreadyPublished:(NSString *)srcPath outDir:(NSString *)outDir resolution:(NSString *)resolution
{
    NSString *ssDir = [srcPath stringByDeletingLastPathComponent];
    NSString *ssDirRel = [ResourceManagerUtil relativePathFromAbsolutePath:ssDir];
    NSString *ssName = [ssDir lastPathComponent];

    NSDate *srcDate = [self modifiedDateOfSpriteSheetDirectory:ssDir];

    BOOL isDirty = [_projectSettings isDirtyRelPath:ssDirRel];

    // Make the name for the final sprite sheet
    NSString *ssDstPath = [[[[outDir stringByDeletingLastPathComponent]
                                     stringByAppendingPathComponent:[NSString stringWithFormat:@"resources-%@", resolution]]
                                     stringByAppendingPathComponent:ssName] stringByAppendingPathExtension:@"plist"];

    NSDate *ssDstDate = [self modifiedDataOfSpriteSheetFile:ssDstPath];

    return ssDstDate && [ssDstDate isEqualToDate:srcDate] && !isDirty;
}

// TODO: spritesheet logic needed in here?
- (NSDate *)modifiedDataOfSpriteSheetFile:(NSString *)spriteSheetFile
{
    id ssDstDate = [_modifiedFileDateCache cachedDateForKey:spriteSheetFile];

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
            [_modifiedFileDateCache setCachedDate:[NSNull null] forKey:spriteSheetFile];
        }
        else
        {
            [_modifiedFileDateCache setCachedDate:ssDstDate forKey:spriteSheetFile];
        }
    }

    return ssDstDate;
}

// TODO: spritesheet logic needed in here?
- (NSDate *)modifiedDateOfSpriteSheetDirectory:(NSString *)directory
{
    NSDate *srcDate = [_modifiedFileDateCache cachedDateForKey:directory];
    if (!srcDate)
    {
        srcDate = [self latestModifiedDateForDirectory:directory];
        [_modifiedFileDateCache setCachedDate:srcDate forKey:directory];
    }
    return srcDate;
}

- (NSString *)pathWithCocoaImageResolutionSuffix:(NSString *)path resolution:(NSString *)resolution
{
    NSString *extension = [path pathExtension];

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

- (NSDate *)latestModifiedDateForDirectory:(NSString *)dir
{
    NSDate *latestDate = [CCBFileUtil modificationDateForFile:dir];

    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dir error:NULL];
    for (NSString *file in files)
    {
        NSString *absFile = [dir stringByAppendingPathComponent:file];

        BOOL isDir = NO;
        if ([[NSFileManager defaultManager] fileExistsAtPath:absFile isDirectory:&isDir])
        {
            NSDate *fileDate = NULL;

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

@end