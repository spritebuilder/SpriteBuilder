#import "AllDocumentsMigrator.h"
#import "ProjectSettings.h"
#import "CCRenderer_Private.h"
#import "CCBDictionaryMigrator.h"
#import "CCBReader_Private.h"
#import "CCBDictionaryReader.h"
#import "NSString+Misc.h"
#import "MigrationLogger.h"

static NSString *const LOGGER_SECTION = @"AllDocumentsMigrator";
static NSString *const LOGGER_ROLLBACK = @"Rollback";


@interface AllDocumentsMigrator ()

@property (nonatomic, strong) NSString *dirPath;
@property (nonatomic) NSUInteger migrationVersionTarget;
@property (nonatomic, strong) NSMutableArray *documentMigrators;
@property (nonatomic, strong) NSArray *allDocuments;
@property (nonatomic, strong) MigrationLogger *logger;

@end


@implementation AllDocumentsMigrator

- (instancetype)initWithDirPath:(NSString *)dirPath toVersion:(NSUInteger)toVersion
{
    NSAssert(dirPath != nil, @"dirPath must not be nil");
    NSAssert(toVersion > 0, @"toVersion must be greate than 0");

    self = [super init];

    if (self)
    {
        self.migrationVersionTarget = toVersion;
        self.dirPath = dirPath;
        self.documentMigrators = [NSMutableArray array];
    }

    return self;
}

- (void)setLogger:(MigrationLogger *)migrationLogger
{
    _logger = migrationLogger;
}

- (NSArray *)allDocuments
{
    if (!_allDocuments)
    {
        self.allDocuments = [_dirPath allFilesInDirWithFilterBlock:^BOOL(NSURL *fileURL)
        {
            NSString *filename;
            [fileURL getResourceValue:&filename forKey:NSURLNameKey error:nil];

            NSNumber *isDirectory;
            [fileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];

            return [self isDocumentFile:fileURL isDirectory:isDirectory];
        }];
    }

    return _allDocuments;
}

- (BOOL)isDocumentFile:(NSURL *)fileURL isDirectory:(NSNumber *)isDirectory
{
    return ![isDirectory boolValue]
            && ([[fileURL relativeString] hasSuffix:@"ccb"]
                || [[fileURL relativeString] hasSuffix:@"sb"]);
}

- (BOOL)isMigrationRequired
{
    for (NSString *documentPath in self.allDocuments)
    {
        CCBDictionaryMigrator *migrator = [[CCBDictionaryMigrator alloc] initWithFilepath:documentPath
                                                                                toVersion:_migrationVersionTarget];
        if ([migrator isMigrationRequired])
        {
            return YES;
        }
    }

    return NO;
}

- (BOOL)migrateWithError:(NSError **)error
{
    if (![self isMigrationRequired])
    {
        return YES;
    }

    [_logger log:@"Starting..." section:@[LOGGER_SECTION]];

    for (NSString *documentPath in self.allDocuments)
    {
        CCBDictionaryMigrator *migrator = [[CCBDictionaryMigrator alloc] initWithFilepath:documentPath
                                                                                toVersion:_migrationVersionTarget];
        [_documentMigrators addObject:migrator];

        if (![migrator migrateWithError:error])
        {
            return NO;
        }
    }

    [_logger log:@"Finished successfully!" section:@[LOGGER_SECTION]];

    return YES;
}

- (void)rollback
{
    [_logger log:@"Starting..." section:@[LOGGER_SECTION, LOGGER_ROLLBACK]];
    for (id<MigratorProtocol> migrator in _documentMigrators)
    {
        [migrator rollback];
    }
    [_logger log:@"Finished" section:@[LOGGER_SECTION, LOGGER_ROLLBACK]];
}

- (void)tidyUp
{
    for (id<MigratorProtocol> migrator in _documentMigrators)
    {
        [migrator tidyUp];
    }
}

@end
