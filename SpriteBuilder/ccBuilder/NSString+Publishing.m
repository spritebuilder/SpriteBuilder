#import "NSString+Publishing.h"
#import "CCBFileUtil.h"
#import "ResourceManager.h"
#import "MiscConstants.h"


@implementation NSString (Publishing)

- (NSString *)resourceAutoFilePath
{
    NSString *filename = [self lastPathComponent];
    NSString *directory = [self stringByDeletingLastPathComponent];
    NSString *autoDir = [directory stringByAppendingPathComponent:@"resources-auto"];
    return [autoDir stringByAppendingPathComponent:filename];
}

- (BOOL)isResourceAutoFile
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *filepath = [self resourceAutoFilePath];

    return [fileManager fileExistsAtPath:filepath];
}

- (BOOL)isWaveSoundFile
{
    NSString *extension = [[self pathExtension] lowercaseString];
    return [extension isEqualToString:@"wav"];
}

- (BOOL)isSmartSpriteSheetCompatibleFile
{
    NSString *extension = [[self pathExtension] lowercaseString];
    return [extension isEqualToString:@"png"] || [extension isEqualToString:@"psd"];
}

- (NSDate *)latestModifiedDateOfPathIgnoringDirs:(BOOL)ignoreDirs
{
    return [self latestModifiedDateForDirectory:self ignoreDirs:ignoreDirs];
}

- (NSDate *)latestModifiedDateForDirectory:(NSString *)dir ignoreDirs:(BOOL)ignoreDirs
{
	NSDate* latestDate = ignoreDirs
        ? [NSDate distantPast]
        : [CCBFileUtil modificationDateForFile:dir];

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
				fileDate = [self latestModifiedDateForDirectory:absFile ignoreDirs:ignoreDirs];
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

- (NSArray *)allPNGFilesInPath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtURL:[NSURL URLWithString:self]
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

- (NSArray *)filesInAutoDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];;
	NSMutableArray *result = [NSMutableArray array];
	NSString* autoDir = [self stringByAppendingPathComponent:@"resources-auto"];
	BOOL isDirAuto;
	if ([fileManager fileExistsAtPath:autoDir isDirectory:&isDirAuto] && isDirAuto)
    {
        [result addObjectsFromArray:[fileManager contentsOfDirectoryAtPath:autoDir error:NULL]];
    }
	return result;
}

- (NSArray *)resolutionDependantFilesInDirWithResolutions:(NSArray *)resolutions
{
    NSFileManager *fileManager = [NSFileManager defaultManager];;
	NSMutableArray *result = [NSMutableArray array];

	for (NSString *publishExt in resolutions)
	{
		NSString *resolutionDir = [self stringByAppendingPathComponent:publishExt];
		BOOL isDirectory;
		if ([fileManager fileExistsAtPath:resolutionDir isDirectory:&isDirectory] && isDirectory)
		{
			[result addObjectsFromArray:[fileManager contentsOfDirectoryAtPath:resolutionDir error:NULL]];
		}
	}

	return result;
}

- (BOOL)containsCCBFile
{
    return [self containsCCBFile:self];
}

- (BOOL) containsCCBFile:(NSString*) dir
{
    NSFileManager* fm = [NSFileManager defaultManager];
    NSArray* files = [fm contentsOfDirectoryAtPath:self error:NULL];
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

- (BOOL)isIntermediateFileLookup
{
    return [self isEqualToString:INTERMEDIATE_FILE_LOOKUP_NAME];
}

@end