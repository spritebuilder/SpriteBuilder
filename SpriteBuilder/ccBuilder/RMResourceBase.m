#import "RMResourceBase.h"
#import "RMDirectory.h"
#import "RMResource.h"


@implementation RMResourceBase

- (NSString *)fullPath
{
    NSString *fullPath;
    if ([self isKindOfClass:[RMDirectory class]])
    {
        fullPath = ((RMDirectory *) self).dirPath;
    }
    else if ([self isKindOfClass:[RMResource class]])
    {
        fullPath = ((RMResource *) self).filePath;
    }

    // if it doesn't exist, peek inside "resources-auto" (only needed in the case of resources, which has a different visual
    // layout than what is actually on the disk).
    // Should probably be removed and pulled into [RMResource filePath]
    if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath] == NO)
    {
        NSString *filename = [fullPath lastPathComponent];
        NSString *directory = [fullPath stringByDeletingLastPathComponent];
        fullPath = [NSString pathWithComponents:[NSArray arrayWithObjects:directory, @"resources-auto", filename, nil]];
    }

    if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath] == NO)
    {
        return nil;
    }

    return fullPath;
}

@end