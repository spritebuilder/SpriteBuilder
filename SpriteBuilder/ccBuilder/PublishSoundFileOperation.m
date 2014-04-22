#import "PublishSoundFileOperation.h"
#import "CCBFileUtil.h"
#import "FCFormatConverter.h"
#import "CCBWarnings.h"


@implementation PublishSoundFileOperation

- (void)main
{
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm copyItemAtPath:_srcFilePath toPath:_dstFilePath error:NULL];

    self.dstFilePath = [[FCFormatConverter defaultConverter] convertSoundAtPath:_dstFilePath format:_format quality:_quality];
    if (!_dstFilePath)
    {
        [_warnings addWarningWithDescription:[NSString stringWithFormat:@"Failed to convert audio file %@", _relativePath] isFatal:NO];
        return;
    }

    [CCBFileUtil setModificationDate:[CCBFileUtil modificationDateForFile:_srcFilePath] forFile:_dstFilePath];
}

- (void)cancel
{
    // TODO
    [super cancel];
}

@end