#import "Cocos2dUpater+Errors.h"
#import "SBErrors.h"

@implementation Cocos2dUpater (Errors)

- (NSError *)errorForFailedUnzipTask:(NSString *)zipFile dataStdOut:(NSData *)dataStdOut dataStdErr:(NSData *)dataStdErr status:(int)status
{
    NSString *stdOut = [[NSString alloc] initWithData: dataStdOut encoding: NSUTF8StringEncoding];
    NSString *stdErr = [[NSString alloc] initWithData: dataStdErr encoding: NSUTF8StringEncoding];

    NSDictionary *userInfo = @{
            @"zipFile" : zipFile,
            @"stdOut" : stdOut,
            @"stdErr" : stdErr,
            NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Unzip task exited with status code %d. See stdErr key in userInfo.", status]};

    return [NSError errorWithDomain:SBErrorDomain
                               code:SBCocos2dUpdateUnzipTemplateFailedError
                           userInfo:userInfo];
}

- (NSError *)errorForUnzipTaskWithException:(NSException *)exception zipFile:(NSString *)zipFile
{
    NSDictionary *userInfo = @{
            @"zipFile" : zipFile,
            @"exception" : exception,
            NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Exception %@ thrown while running unzip task.", exception.name]};

    return [NSError errorWithDomain:SBErrorDomain
                                     code:SBCocos2dUpdateUnzipTaskError
                                 userInfo:userInfo];
}

- (NSError *)errorForNonExistentTemplateFile:(NSString *)zipFile
{
    NSDictionary *userInfo = @{
            @"zipFile" : zipFile,
            NSLocalizedDescriptionKey : @"Project template zip file does not exist, unable to extract newer cocos2d version."};

    return [NSError errorWithDomain:SBErrorDomain
                                     code:SBCocos2dUpdateTemplateZipFileDoesNotExistError
                                 userInfo:userInfo];
}

@end