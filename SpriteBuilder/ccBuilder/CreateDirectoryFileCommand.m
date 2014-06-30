#import "CreateDirectoryFileCommand.h"

@implementation CreateDirectoryFileCommand

- (instancetype)initWithDirPath:(NSString *)dirPath
{
    self = [super init];
    if (self)
    {
        self.dirPath = dirPath;
    }

    return self;
}

- (BOOL)execute:(NSError **)error
{
    NSAssert(_dirPath != nil, @"dirPath must be set");

    NSFileManager *fileManager = [NSFileManager defaultManager];

    return [fileManager createDirectoryAtPath:_dirPath
                  withIntermediateDirectories:YES
                                   attributes:nil
                                        error:error];
}

- (BOOL)undo:(NSError **)error
{
    NSAssert(_dirPath != nil, @"dirPath must be set");

    NSFileManager *fileManager = [NSFileManager defaultManager];

    return [fileManager removeItemAtPath:_dirPath error:error];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"Create directory at \"%@\"", _dirPath];
}

@end