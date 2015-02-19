#import "CCBDictionaryMigrator.h"
#import "CCBReader_Private.h"
#import "CCBDictionaryReader.h"
#import "CCBDictionaryMigrationProtocol.h"
#import "CCBDictionaryKeys.h"
#import "NSString+Misc.h"
#import "NSError+SBErrors.h"
#import "Errors.h"
#import "BackupFileCommand.h"


@interface CCBDictionaryMigrator()

@property (nonatomic, copy) NSString *filepath;

@property (nonatomic) NSUInteger migrationVersionTarget;
@property (nonatomic, copy) NSDictionary *document;
@property (nonatomic, copy, readwrite) NSDictionary *migratedDocument;
@property (nonatomic, strong) NSError *migrationError;

@property (nonatomic) BackupFileCommand *backupFileCommand;

@end


@implementation CCBDictionaryMigrator

- (id)initWithFilepath:(NSString *)filepath toVersion:(NSUInteger)toVersion
{
    NSAssert(filepath != nil, @"filepath must not be nil");
    NSAssert(toVersion > 0, @"toVersion must be greater than 0");

    self = [super init];
    if (self)
    {
        self.filepath = filepath;
        self.migrationVersionTarget = toVersion;
        self.migrationStepClassPrefix = @"CCBDictionaryMigrationStepVersion";
    }

    return self;
}

- (NSDictionary *)document
{
    if (!_document)
    {
        self.document = [NSDictionary dictionaryWithContentsOfFile:_filepath];
        if (!_document)
        {
            self.migrationError = [NSError errorWithDomain:SBErrorDomain code:SBCCBMigrationError userInfo:@{
                NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Migration error: Document at \"%@\" could not be loaded.", _filepath]
            }];
        };
    }

    return _document;
}

- (NSDictionary *)migratedDocument
{
    if (!_migratedDocument)
    {
        NSError *error;
        self.migratedDocument = [self migrate:&error];
        self.migrationError = error;
    }

    return _migratedDocument;
}

- (NSDictionary *)migrate:(NSError **)error
{
    if (![self proceedWithMigration:error])
    {
        return nil;
    }

    int fileVersion = [_document[CCB_DICTIONARY_KEY_FILEVERSION] intValue];

    if (fileVersion >= _migrationVersionTarget)
    {
        return _document;
    }

    NSDictionary *migratedCCB = _document;

    int currentVersionPass = fileVersion;
    while(currentVersionPass < _migrationVersionTarget)
    {
        Class migrationStepClass = NSClassFromString([NSString stringWithFormat:@"%@%d", _migrationStepClassPrefix, currentVersionPass]);

        currentVersionPass++;

        if (!migrationStepClass)
        {
            continue;
        }

        id migrationStep = (id) [[migrationStepClass alloc] init];
        if (![migrationStep conformsToProtocol:@protocol(CCBDictionaryMigrationProtocol)])
        {
            continue;
        }

        NSError *underylingError;
        migratedCCB = [migrationStep migrate:migratedCCB error:&underylingError];

        if (!migratedCCB)
        {
            [NSError setNewErrorWithErrorPointer:error
                                            code:SBCCBMigrationError
                                        userInfo:@{
                                                NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Migration failed for version %d. See NSUnderlyingErrorKey for details.", currentVersionPass],
                                                NSUnderlyingErrorKey : underylingError
                                        }];
            return nil;
        };
    }

    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithDictionary:migratedCCB];

    result[CCB_DICTIONARY_KEY_FILEVERSION] = @(_migrationVersionTarget);

    return result;
}

- (BOOL)proceedWithMigration:(NSError **)error
{
    if (!self.document)
    {
        [NSError setError:error withError:_migrationError];
        return NO;
    }

    if (!_migrationStepClassPrefix || [_migrationStepClassPrefix isEmpty])
    {
        [NSError setNewErrorWithErrorPointer:error
                                        code:SBCCBMigrationNoMigrationStepClassPrefixError
                                     message:@"Class prefix for migration step classes is empty or nil"];
        return NO;
    }

    if (!_document[CCB_DICTIONARY_KEY_FILEVERSION])
    {
        [NSError setNewErrorWithErrorPointer:error
                                        code:SBCCBMigrationNoVersionFoundError
                                     message:@"Could not determine ccb's version"];
        return NO;
    }
    return YES;
}

- (NSString *)htmlInfoText
{
    return @"Document requires migration to a newer version.";
}

- (BOOL)migrationRequired
{
    NSDictionary *dict = self.document;

    // Doing the actual migration, it's not expensive to so the result can be compared to the
    // file's content to see if it changed. Everything else may turn out in alot more code than the needed migration steps.
    NSDictionary *result = self.migratedDocument;

    // If there was an error there's no real way to tell at this point so
    // a migration is required to let a caller run into the actual error with the migrate method
    if (!result)
    {
        return YES;
    }

    return ![dict isEqualToDictionary:result];

}

- (BOOL)migrateWithError:(NSError **)error
{
    if (![self migrationRequired])
    {
        return YES;
    }

    if (![self createBackupWithError:error])
    {
        return NO;
    }

    return [self migrate__:error];
}

- (BOOL)migrate__:(NSError **)error
{
    if (self.migratedDocument == nil)
    {
        [NSError setError:error withError:_migrationError];
        return NO;
    }

    NSError *overwriteError;
    if (![self overwriteDocument:&overwriteError])
    {
        [NSError setNewErrorWithErrorPointer:error
                                        code:SBMigrationError
                                    userInfo:@{
                                            NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Could not overwrite existing Package Settings with migrated version at \"%@\"", _filepath],
                                            NSUnderlyingErrorKey : overwriteError
                                    }];
        return NO;
    };
    return YES;
}

- (BOOL)overwriteDocument:(NSError **)error
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager removeItemAtPath:_filepath error:error])
    {
        return NO;
    }

    if (![self.migratedDocument writeToFile:_filepath atomically:YES])
    {
        [NSError setNewErrorWithErrorPointer:error code:SBMigrationError message:@"Dictionary Write error"];
        return NO;
    }
    return YES;
}

- (BOOL)createBackupWithError:(NSError **)error
{
    self.backupFileCommand = [[BackupFileCommand alloc] initWithFilePath:_filepath];
    NSError *backupError;
    if (![_backupFileCommand execute:&backupError])
    {
        [NSError setNewErrorWithErrorPointer:error code:SBMigrationError userInfo:@{
                NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Could not create backup file of package settings at \"%@\"", _filepath],
                NSUnderlyingErrorKey : backupError
        }];
        return NO;
    };
    return YES;
}

- (void)rollback
{
    [_backupFileCommand undo:nil];
}

- (void)tidyUp
{
    [_backupFileCommand tidyUp];
}

@end
