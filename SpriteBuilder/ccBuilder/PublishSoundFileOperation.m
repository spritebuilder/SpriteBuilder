#import "PublishSoundFileOperation.h"

#import "CCBFileUtil.h"
#import "FCFormatConverter.h"
#import "CCBWarnings.h"
#import "ProjectSettings.h"
#import "ResourceManagerUtil.h"
#import "PublishRenamedFilesLookup.h"
#import "PublishingTaskStatusProgress.h"


@interface PublishSoundFileOperation ()

@property (nonatomic, strong) FCFormatConverter *formatConverter;

@end

@implementation PublishSoundFileOperation

- (void)main
{
    NSLog(@"[%@] %@ -> %@", [self class], [_srcFilePath lastPathComponent], [_dstFilePath lastPathComponent]);

    [self publishSoundFileOperation];

    [_publishingTaskStatusProgress taskFinished];
}

- (void)publishSoundFileOperation
{
    [_publishingTaskStatusProgress updateStatusText:@"Converting sound file"];

    NSString *relPath = [ResourceManagerUtil relativePathFromAbsolutePath:_srcFilePath];

    [_fileLookup addRenamingRuleFrom:relPath to:[[FCFormatConverter defaultConverter] proposedNameForConvertedSoundAtPath:relPath
                                                                                                                format:_format
                                                                                                               quality:_quality]];

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

    self.formatConverter = [FCFormatConverter defaultConverter];
    self.dstFilePath = [_formatConverter convertSoundAtPath:_dstFilePath format:_format quality:_quality];
    if (!_dstFilePath)
    {
        [_warnings addWarningWithDescription:[NSString stringWithFormat:@"Failed to convert audio file %@", relPath] isFatal:NO];
        self.formatConverter = nil;
        return;
    }
    self.formatConverter = nil;

    [CCBFileUtil setModificationDate:[CCBFileUtil modificationDateForFile:_srcFilePath] forFile:_dstFilePath];
}

- (void)cancel
{
    NSLog(@"[%@] CANCELLED %@ ", [self class], [_srcFilePath lastPathComponent]);

    [super cancel];
    [_formatConverter cancel];
}

@end