#import "MoveFileCommand.h"

@interface MoveFileCommand()

@end


@implementation MoveFileCommand

- (instancetype)initWithFromPath:(NSString *)fromPath toPath:(NSString *)toPath
{
    self = [super init];
    if (self)
    {
        self.fromPath = fromPath;
        self.toPath = toPath;
    }

    return self;
}

- (BOOL)execute:(NSError **)error
{
    NSAssert(_fromPath != nil, @"fromPath must be set");
    NSAssert(_toPath != nil, @"toPath must be set");

    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager moveItemAtPath:_fromPath toPath:_toPath error:error];
}

- (BOOL)undo:(NSError **)error;
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager moveItemAtPath:_toPath toPath:_fromPath error:error];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"Move file from:\"%@\" to:\"%@\"", _fromPath, _toPath];
}

@end