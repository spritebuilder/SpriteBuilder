#import "MoveFileCommand.h"

@interface MoveFileCommand()

@property (nonatomic, readwrite) BOOL successful;
@property (nonatomic, strong, readwrite) NSError *error;

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
    if (![fileManager moveItemAtPath:_fromPath toPath:_toPath error:error])
    {
        self.error = *error;
        return NO;
    }

    self.successful = YES;
    return YES;
}

- (BOOL)undo:(NSError **)error;
{
    if (_successful)
    {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager moveItemAtPath:_toPath toPath:_fromPath error:error])
        {
            return NO;
        }
    }
    else
    {
        NSLog(@"Nothing to undo: %@", [self description]);
    }
    return YES;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"[%@] from:\"%@\" to:\"%@\"", [self class], _fromPath, _toPath];
}

@end