#import "PublishRegularFileOperation.h"

#import "CCBFileUtil.h"
#import "PublishingTaskStatusProgress.h"
#import "PublishLogging.h"


@implementation PublishRegularFileOperation

- (void)main
{
    [super main];

    [self assertProperties];

    [self publishRegularFile];

    [_publishingTaskStatusProgress taskFinished];
}

- (void)assertProperties
{
    NSAssert(_srcFilePath != nil, @"srcFilePath should not be nil");
    NSAssert(_dstFilePath != nil, @"dstFilePath should not be nil");
}

- (void)publishRegularFile
{
    NSDate *srcDate = [CCBFileUtil modificationDateForFile:_srcFilePath];
    NSDate *dstDate = [CCBFileUtil modificationDateForFile:_dstFilePath];

    // Check if file already exists
    if ([[NSFileManager defaultManager] fileExistsAtPath:_dstFilePath] &&
        [srcDate isEqualToDate:dstDate])
    {
        LocalLog(@"[%@] SKIPPING file exists and dates (src: %@, dst: %@) are equal - %@", [self class], srcDate, dstDate, [self description]);
        return;
    }

    // Copy file and make sure modification date is the same as for src file
    [[NSFileManager defaultManager] removeItemAtPath:_dstFilePath error:NULL];
    [[NSFileManager defaultManager] copyItemAtPath:_srcFilePath toPath:_dstFilePath error:NULL];
    [CCBFileUtil setModificationDate:[CCBFileUtil modificationDateForFile:_srcFilePath] forFile:_dstFilePath];
}

- (void)cancel
{
    [super cancel];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"src: %@, dst: %@, srcfull: %@, dstfull: %@", [_srcFilePath lastPathComponent], [_dstFilePath lastPathComponent], _srcFilePath, _dstFilePath];
}

@end