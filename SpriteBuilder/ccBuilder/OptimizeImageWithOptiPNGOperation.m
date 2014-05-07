#import "OptimizeImageWithOptiPNGOperation.h"

#import "CCBWarnings.h"
#import "PublishingTaskStatusProgress.h"


@interface OptimizeImageWithOptiPNGOperation()

@property (nonatomic, strong) NSTask *task;

@end


@implementation OptimizeImageWithOptiPNGOperation

- (void)main
{
    [super main];

    [self assertProperties];

    [self optimizeImageWithOptiPNG];

    [_publishingTaskStatusProgress taskFinished];
}

- (void)assertProperties
{
    NSAssert(_filePath != nil, @"filePath should not be nil");
    NSAssert(_optiPngPath != nil, @"optiPngPath should not be nil");
}

- (void)optimizeImageWithOptiPNG
{
    [_publishingTaskStatusProgress updateStatusText:[NSString stringWithFormat:@"Optimizing %@...", [_filePath lastPathComponent]]];

    self.task = [[NSTask alloc] init];
    [_task setLaunchPath:_optiPngPath];
    [_task setArguments:@[_filePath]];

    // NSPipe *pipe = [NSPipe pipe];
    NSPipe *pipeErr = [NSPipe pipe];
    [_task setStandardError:pipeErr];

    // [_task setStandardOutput:pipe];
    // NSFileHandle *file = [pipe fileHandleForReading];

    NSFileHandle *fileErr = [pipeErr fileHandleForReading];

    int status = 0;

    @try
    {
        [_task launch];
        [_task waitUntilExit];
        status = [_task terminationStatus];
    }
    @catch (NSException *ex)
    {
        NSLog(@"[%@] %@", [self class], ex);
        return;
    }

    if (status)
    {
        NSData *data = [fileErr readDataToEndOfFile];
        NSString *stdErrOutput = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSString *warningDescription = [NSString stringWithFormat:@"optipng error: %@", stdErrOutput];
        [_warnings addWarningWithDescription:warningDescription];
    }
}

- (void)cancel
{
    @try
    {
        [super cancel];
        [_task terminate];
    }
    @catch (NSException *exception)
    {
        NSLog(@"Exception: %@", exception);
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"file: %@, file full: %@, optipng: %@", [_filePath lastPathComponent], _filePath, _optiPngPath];
}

@end