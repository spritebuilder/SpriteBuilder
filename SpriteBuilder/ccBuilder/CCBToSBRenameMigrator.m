#import "CCBToSBRenameMigrator.h"
#import "CCRenderer_Private.h"
#import "NSString+Misc.h"
#import "FileCommandProtocol.h"
#import "CCBDocumentManipulator.h"
#import "BackupFileCommand.h"
#import "NSError+SBErrors.h"
#import "Errors.h"
#import "MoveFileCommand.h"


@interface CCBToSBRenameMigrator()

@property (nonatomic, strong) NSString *dirPath;
@property (nonatomic, strong) NSMutableArray *commands;
@property (nonatomic, strong) NSArray *allDocuments;

@end


@implementation CCBToSBRenameMigrator

- (id)initWithDirPath:(NSString *)dirPath
{
    NSAssert(dirPath != nil, @"dirPath must not be nil");

    self = [super init];

    if (self)
    {
        self.dirPath = dirPath;
        self.commands = [NSMutableArray array];
    }

    return self;
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

            return ![isDirectory boolValue]
                   && ([[fileURL relativeString] hasSuffix:@"ccb"]);
        }];
    }

    return _allDocuments;
}

- (NSString *)htmlInfoText
{
    return @"Some old ccb file extensions found. Renaming of files to sb extension required, also references to ccb files within those documents.";
}

- (BOOL)isMigrationRequired
{
    return [self.allDocuments count] > 0;
}

- (BOOL)migrateWithError:(NSError **)error
{
    if (![self isMigrationRequired])
    {
        return YES;
    }

    for (NSString *documentPath in self.allDocuments)
    {
        if (![self renameCCBFileToSB:documentPath error:error])
        {
            return NO;
        }
    }

    return YES;
}

- (BOOL)renameCCBFileToSB:(NSString *)path error:(NSError **)error
{
    NSString *newPath = [path replaceExtension:@"sb"];

    MoveFileCommand *moveFileCommand = [[MoveFileCommand alloc] initWithFromPath:path toPath:newPath];

    if (![moveFileCommand execute:error])
    {
        return NO;
    }

    [_commands addObject:moveFileCommand];

    return YES;
}

- (void)rollback
{
    for (id <FileCommandProtocol> command in _commands)
    {
        NSError *error;
        if (![command undo:&error])
        {
            NSLog(@"[MIGRATION] Could not rollback ccb to sb renaming command: %@", error);
        }
    }
}

- (void)tidyUp
{
    for (id <FileCommandProtocol> command in _commands)
    {
        if ([command respondsToSelector:@selector(tidyUp)])
        {
            [command tidyUp];
        }
    }
}

@end
