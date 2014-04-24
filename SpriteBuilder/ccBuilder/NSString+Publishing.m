#import "NSString+Publishing.h"


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

@end