#import "PublishRegularFileOperation.h"
#import "CCBFileUtil.h"


@implementation PublishRegularFileOperation

- (instancetype)initWithSrcFilePath:(NSString *)srcFilePath dstFilePath:(NSString *)dstFilePath
{
    self = [super init];

    if (self)
    {
        self.srcFilePath = srcFilePath;
        self.dstFilePath = dstFilePath;
    }

    return self;
}

- (void)main
{
    // Check if file already exists
    if ([[NSFileManager defaultManager] fileExistsAtPath:_dstFilePath] &&
        [[CCBFileUtil modificationDateForFile:_srcFilePath] isEqualToDate:[CCBFileUtil modificationDateForFile:_dstFilePath]])
    {
        return;
    }

    // Copy file and make sure modification date is the same as for src file
    [[NSFileManager defaultManager] removeItemAtPath:_dstFilePath error:NULL];
    [[NSFileManager defaultManager] copyItemAtPath:_srcFilePath toPath:_dstFilePath error:NULL];
    [CCBFileUtil setModificationDate:[CCBFileUtil modificationDateForFile:_srcFilePath] forFile:_dstFilePath];
}

@end