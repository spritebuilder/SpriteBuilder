#import "NSString+Misc.h"
#import "CCEffect_Private.h"


@implementation NSString (Misc)

- (BOOL)isEmpty
{
    return [self length] == 0
           || ![[self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length];

}

- (NSString *)availabeFileNameWithRollingNumberAndExtraExtension:(NSString *)extension
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:self])
    {
        return nil;
    }

    NSString *path = [self stringByDeletingLastPathComponent];
    NSArray *dirContents = [fileManager contentsOfDirectoryAtPath:path error:nil];

    if (!dirContents)
    {
        return nil;
    }

    NSUInteger maxCounter = 0;
    for (NSString *filename in dirContents)
    {
        maxCounter = [self highestBackupDirCounterPostfixCurrentCount:maxCounter filename:[path stringByAppendingPathComponent:filename] postfix:extension];
    }

    NSString *result = extension && ![extension isEmpty]
        ? [self stringByAppendingPathExtension:extension]
        : self;

    return [result stringByAppendingPathExtension:[NSString stringWithFormat:@"%lu", maxCounter]];
}

- (NSUInteger)highestBackupDirCounterPostfixCurrentCount:(NSUInteger)currentCounter filename:(NSString *)directoryName postfix:(NSString *)postfix
{
    NSNumber *number = [self parseNumberPostfixInBackupDir:directoryName extension:postfix];

    if (number
        && ([number unsignedIntegerValue] > currentCounter))
    {
        currentCounter = [number unsignedIntegerValue] + 1;
    }

    return currentCounter;
}

- (NSNumber *)parseNumberPostfixInBackupDir:(NSString *)directoryName extension:(NSString *)extension
{
    NSString *baa2 = [directoryName stringByReplacingOccurrencesOfString:self withString:@""];
    NSString *baa = [baa2 stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@".%@", extension] withString:@""];
    NSScanner *scanner = [NSScanner scannerWithString:baa];
    scanner.charactersToBeSkipped = [NSCharacterSet characterSetWithCharactersInString:@"."];

    NSInteger result;
    if ([scanner scanInteger:&result])
    {
        return @(result);
    }

    return nil;
}

- (NSArray *)allFilesInDirWithFilterBlock:(FileFilterBlock)block
{
    NSFileManager *fileManager = [NSFileManager defaultManager];

    if (![fileManager fileExistsAtPath:self])
    {
        return nil;
    }

    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtURL:[NSURL fileURLWithPath:self]
                                          includingPropertiesForKeys:@[NSURLNameKey, NSURLIsDirectoryKey]
                                                             options:NSDirectoryEnumerationSkipsHiddenFiles
                                                        errorHandler:^BOOL(NSURL *url, NSError *error)
    {
        return YES;
    }];

    NSMutableArray *mutableFileURLs = [NSMutableArray array];
    for (NSURL *fileURL in enumerator)
    {
        if (!block)
        {
            [mutableFileURLs addObject:fileURL.path];
        }

        if (block(fileURL))
        {
            [mutableFileURLs addObject:fileURL.path];
        }
    }

    return mutableFileURLs;

}

- (NSString *)replaceExtension:(NSString *)newExtension
{
    NSRange range = [self rangeOfString:@"." options:NSBackwardsSearch];

    if (range.location != NSNotFound)
    {
        NSRange newRange = NSMakeRange(range.location + 1, [self length] - range.location - 1);
        if (newRange.location + newRange.length > [self length])
        {
            return self;
        }

        return [self stringByReplacingCharactersInRange:newRange withString:newExtension];
    }

    return self;
}

@end
