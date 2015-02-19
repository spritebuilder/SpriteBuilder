#import "AllDocumentsMigrator.h"
#import "ProjectSettings.h"
#import "CCRenderer_Private.h"
#import "CCBDictionaryMigrator.h"
#import "CCBReader_Private.h"
#import "CCBDictionaryReader.h"

@interface AllDocumentsMigrator()

@property (nonatomic, strong) NSString *dirPath;
@property (nonatomic) NSUInteger migrationVersionTarget;
@property (nonatomic, strong) NSMutableArray *documentMigrators;
@property (nonatomic, strong) NSArray *allDocuments;

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

- (NSArray *)allDocuments
{
    if (!_allDocuments)
    {
        self.allDocuments = [self allDocumentsInFilePath];
    }

    return _allDocuments;
}

- (NSArray *)allDocumentsInFilePath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtURL:[NSURL fileURLWithPath:_dirPath]
                                          includingPropertiesForKeys:@[NSURLNameKey, NSURLIsDirectoryKey]
                                                             options:NSDirectoryEnumerationSkipsHiddenFiles
                                                        errorHandler:^BOOL(NSURL *url, NSError *error)
    {
        return YES;
    }];

    NSMutableArray *mutableFileURLs = [NSMutableArray array];
    for (NSURL *fileURL in enumerator)
    {
        NSString *filename;
        [fileURL getResourceValue:&filename forKey:NSURLNameKey error:nil];

        NSNumber *isDirectory;
        [fileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];

        if ([self isDocumentFile:fileURL isDirectory:isDirectory])
        {
            [mutableFileURLs addObject:fileURL.path];
        }
    }

    return mutableFileURLs;
}

- (BOOL)isDocumentFile:(NSURL *)fileURL isDirectory:(NSNumber *)isDirectory
{
    return ![isDirectory boolValue]
            && ([[fileURL relativeString] hasSuffix:@"ccb"] || [[fileURL relativeString] hasSuffix:@"sb"]);
}

- (NSString *)htmlInfoText
{
    return @"Some ccb documents are of an older version. Migration is required.";
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

    return YES;
}

- (void)rollback
{
    for (id<MigratorProtocol> migrator in _documentMigrators)
    {
        [migrator rollback];
    }
}

- (void)tidyUp
{
    for (id<MigratorProtocol> migrator in _documentMigrators)
    {
        [migrator tidyUp];
    }
}

@end
