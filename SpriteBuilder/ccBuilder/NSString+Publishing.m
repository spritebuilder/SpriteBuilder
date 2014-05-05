#import "NSString+Publishing.h"
#import "CCBFileUtil.h"


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

- (BOOL)isSoundFile
{
    NSString *extension = [[self pathExtension] lowercaseString];
    return [extension isEqualToString:@"wav"];
}

- (BOOL)isSmartSpriteSheetCompatibleFile
{
    NSString *extension = [[self pathExtension] lowercaseString];
    return [extension isEqualToString:@"png"] || [extension isEqualToString:@"psd"];
}

- (NSDate *)latestModifiedDateForDirectory
{
    return [self latestModifiedDateForDirectory:self];
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

@end