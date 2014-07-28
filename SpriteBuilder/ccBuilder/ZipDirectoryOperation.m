#import <MacTypes.h>
#import "ZipDirectoryOperation.h"
#import "PublishingTaskStatusProgress.h"
#import "CCBWarnings.h"


@interface ZipDirectoryOperation()

@property (nonatomic, strong) NSTask *task;

@end


@implementation ZipDirectoryOperation

- (void)main
{
    [super main];

    [self assertProperties];

    [self zipDirectory];

    [_publishingTaskStatusProgress taskFinished];
}

- (void)assertProperties
{
    NSAssert(_inputPath, @"inputPath must not be nil");
}

- (void)zipDirectory
{
    NSString *resolvedOutputPath = [self resolvedZipOutputPath];

    [_publishingTaskStatusProgress updateStatusText:[NSString stringWithFormat:@"Zipping %@...", [resolvedOutputPath lastPathComponent]]];
    self.task = [[NSTask alloc] init];

    [self createDirectoriesIfNeeded:resolvedOutputPath];

    [_task setCurrentDirectoryPath:[_inputPath stringByDeletingLastPathComponent]];
    [_task setLaunchPath:@"/usr/bin/zip"];
    [_task setArguments:@[
            @"-dc",
            @"-r",
            [NSString stringWithFormat:@"-%lu", _compression],
            resolvedOutputPath,
            [_inputPath lastPathComponent]
    ]];

    NSPipe *pipe = [NSPipe pipe];
    // Comment this to see output on console
    [_task setStandardOutput:pipe];

    NSPipe *pipeErr = [NSPipe pipe];
    [_task setStandardError:pipeErr];

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

    // Status code reference: http://www.info-zip.org/FAQ.html
    if (status)
    {
        NSData *data = [fileErr readDataToEndOfFile];
        NSString *stdErrOutput = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSString *warningDescription = [NSString stringWithFormat:@"zip exited with code %d, error: %@", status, stdErrOutput];
        [_warnings addWarningWithDescription:warningDescription];
    }
}

- (void)createDirectoriesIfNeeded:(NSString *)resolvedOutputPath
{
    if (_createDirectories)
    {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error;
        if (![fileManager createDirectoryAtPath:[resolvedOutputPath stringByDeletingLastPathComponent]
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:&error])
        {
            NSLog(@"[ZIPOPERATION] failed to create directories: \"%@\" with error %@", [resolvedOutputPath stringByDeletingLastPathComponent], error);
        }
    }
}

- (NSString *)resolvedZipOutputPath
{
    if (!_zipOutputPath)
    {
        return [_inputPath stringByAppendingPathExtension:@"zip"];
    }

    NSString *outputPathWithExtenstion = _zipOutputPath;
    if (![[_zipOutputPath pathExtension] isEqualToString:@"zip"])
    {
        outputPathWithExtenstion = [_zipOutputPath stringByAppendingPathExtension:@"zip"];
    }
    return outputPathWithExtenstion;
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

@end