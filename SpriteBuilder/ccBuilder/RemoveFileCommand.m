#import <MacTypes.h>
#import "RemoveFileCommand.h"

@interface RemoveFileCommand()

@property (nonatomic, copy, readwrite) NSString *filePath;
@property (nonatomic, copy, readwrite) NSString *tempFileName;

@end


@implementation RemoveFileCommand

- (instancetype)initWithFilePath:(NSString *)filePath
{
    NSAssert(filePath != nil, @"filePath must be not nil");

    self = [super init];
    if (self)
    {
        self.filePath = filePath;
    }

    return self;
}

- (BOOL)execute:(NSError **)error
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *tmpDir = [NSTemporaryDirectory() stringByAppendingPathComponent:@"com.spritebuilder/migration"];

    if (![fileManager createDirectoryAtPath:tmpDir withIntermediateDirectories:YES attributes:nil error:error])
    {
        return NO;
    }

    self.tempFileName = [tmpDir stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];

    return [fileManager moveItemAtPath:_filePath toPath:_tempFileName error:error];
}

- (BOOL)undo:(NSError **)error
{
    return [[NSFileManager defaultManager] moveItemAtPath:_tempFileName toPath:_filePath error:error];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"Remove file at \"%@\" move to temp:\"%@\"", _filePath, _tempFileName];
}

@end