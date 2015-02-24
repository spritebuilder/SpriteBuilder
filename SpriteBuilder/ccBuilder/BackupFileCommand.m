#import "BackupFileCommand.h"
#import "NSString+Misc.h"
#import "NSError+SBErrors.h"
#import "Errors.h"

@interface BackupFileCommand()

@property (nonatomic, readwrite) BOOL executed;
@property (nonatomic, readwrite) BOOL undone;

@property (nonatomic, copy, readwrite) NSString *filePath;
@property (nonatomic, copy, readwrite) NSString *backupFilePath;

@end


@implementation BackupFileCommand

- (instancetype)initWithFilePath:(NSString *)filePath
{
    self = [super init];

    if (self)
    {
        self.filePath = filePath;
        self.executed = NO;
        self.undone = NO;
    }

    return self;
}

- (void)tidyUp
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:_backupFilePath error:nil];
}

- (BOOL)execute:(NSError **)error
{
    if (_executed)
    {
        [NSError setNewErrorWithErrorPointer:error code:SBFileCommandBackupAlreadyExecutedError message:[NSString stringWithFormat:@"backup command already executed"]];
        return NO;
    }

    self.backupFilePath = [_filePath availabeFileNameWithRollingNumberAndExtraExtension:@"backup"];

    if (!_backupFilePath)
    {
        [NSError setNewErrorWithErrorPointer:error code:SBFileCommandBackupError message:[NSString stringWithFormat:@"file does not exist or a backup filename could not be determined"]];
        return NO;
    }

    NSFileManager *fileManager = [NSFileManager defaultManager];

    BOOL result = [fileManager copyItemAtPath:_filePath toPath:_backupFilePath error:error];

    self.executed = YES;

    return result;
}

- (BOOL)undo:(NSError **)error
{
    if (!_executed)
    {
        [NSError setNewErrorWithErrorPointer:error code:SBFileCommandBackupCannotUndoNonExecutedCommandError message:[NSString stringWithFormat:@"backup command has not been executed yet"]];
        return NO;
    }

    if (_undone)
    {
        [NSError setNewErrorWithErrorPointer:error code:SBFileCommandBackupAlreadyUndoneError message:[NSString stringWithFormat:@"backup command already undone"]];
        return NO;
    }

    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSError *underLyingError;
    if (![fileManager removeItemAtPath:_filePath error:&underLyingError]
        && underLyingError.code != NSFileNoSuchFileError)
    {
        [NSError setError:error withError:underLyingError];
        return NO;
    }

    BOOL result = [fileManager moveItemAtPath:_backupFilePath toPath:_filePath error:error];

    self.undone = YES;

    return result;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"[BackupFileCommand] - Backed up file: '%@', backup file: '%@'. Executed: %d, undone: %d",
                     _filePath, _backupFilePath, _executed, _undone];
}

@end
