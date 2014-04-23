#import "NSString+CCBResourcePaths.h"


@implementation NSString (CCBResourcePaths)

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

@end