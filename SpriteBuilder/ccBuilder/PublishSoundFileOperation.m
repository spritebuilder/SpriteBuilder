#import "PublishSoundFileOperation.h"
#import "CCBFileUtil.h"
#import "FCFormatConverter.h"
#import "CCBWarnings.h"
#import "ProjectSettings.h"
#import "ResourceManagerUtil.h"


@implementation PublishSoundFileOperation

- (void)main
{
    NSString *relPath = [ResourceManagerUtil relativePathFromAbsolutePath:_srcFilePath];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    self.dstFilePath = [[FCFormatConverter defaultConverter] proposedNameForConvertedSoundAtPath:_dstFilePath format:_format quality:_quality];
    BOOL isDirty = [_projectSettings isDirtyRelPath:relPath];

    // Skip files that are already converted
    if ([fileManager fileExistsAtPath:_dstFilePath]
        && [[CCBFileUtil modificationDateForFile:_srcFilePath] isEqualToDate:[CCBFileUtil modificationDateForFile:_dstFilePath]]
        && !isDirty)
    {
        return;
    }

    [fileManager copyItemAtPath:_srcFilePath toPath:_dstFilePath error:NULL];

    self.dstFilePath = [[FCFormatConverter defaultConverter] convertSoundAtPath:_dstFilePath format:_format quality:_quality];
    if (!_dstFilePath)
    {
        [_warnings addWarningWithDescription:[NSString stringWithFormat:@"Failed to convert audio file %@", relPath] isFatal:NO];
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