#import <XCTest/XCTest.h>
#import "FileSystemTestCase.h"
#import "ProjectSettings.h"


NSString *const TEST_PATH = @"com.spritebuilder.tests";


@interface FileSystemTestCase()

@property (nonatomic, copy, readwrite) NSString *testDirecotoryPath;

@end


@implementation FileSystemTestCase

- (void)dealloc
{
    [self removeTestFolder];
}

- (void)setUp
{
    [super setUp];

    self.fileManager = [NSFileManager defaultManager];

    [self setupFileSystem];
}

- (void)setupFileSystem
{
    [self createEmptyTestDirectory];
}

- (void)createEmptyTestDirectory
{
    NSString *tmpDir = NSTemporaryDirectory();
    NSString *testDir = [tmpDir stringByAppendingPathComponent:TEST_PATH];

    self.testDirecotoryPath = testDir;
    [self removeTestFolder];

    NSError *error;
    if (![_fileManager createDirectoryAtPath:testDir withIntermediateDirectories:YES attributes:nil error:&error])
    {
        XCTFail(@"Error \"%@\" creating test directory", error.localizedDescription);
        return;
    }

    self.testDirecotoryPath = testDir;
}

- (void)tearDown
{
    [self removeTestFolder];

    [super tearDown];
}

- (void)removeTestFolder
{
    NSError *error;

    if ([_fileManager fileExistsAtPath:self.testDirecotoryPath])
    {
        if (![_fileManager removeItemAtPath:_testDirecotoryPath error:&error])
        {
            NSLog(@"Error \"%@\" removing test directory \"%@\", further tests aren't guaranteed to be deterministic. Exiting!", error.localizedDescription, _testDirecotoryPath);
            exit(1);
        }
    }
    self.testDirecotoryPath = nil;
}

- (void)createFolders:(NSArray *)folders
{
    for (NSString *relFolderPath in folders)
    {
        NSString *fullPathForFolder = [_testDirecotoryPath stringByAppendingPathComponent:relFolderPath];
        NSError *error;
        XCTAssertTrue([_fileManager createDirectoryAtPath:fullPathForFolder withIntermediateDirectories:YES attributes:nil error:&error],
                      @"Could not create folder \"%@\", error: %@", fullPathForFolder, error);
    }
}

- (void)createEmptyFiles:(NSArray *)files
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    for (NSString *relFilePath in files)
    {
        NSData *emptyStringData = [@"" dataUsingEncoding:NSUTF8StringEncoding];

        [dictionary setObject:emptyStringData forKey:relFilePath];
    }

    [self createFilesWithContents:dictionary];
}

- (void)createEmptyFilesRelativeToDirectory:(NSString *)relativeDirectory files:(NSArray *)files;
{
    NSMutableArray *filesWithRelPathPrepended = [NSMutableArray array];

    for (NSString *filePath in files)
    {
        NSString *filePathExtended = [relativeDirectory stringByAppendingPathComponent:filePath];
        [filesWithRelPathPrepended addObject:filePathExtended];
    }

    [self createEmptyFiles:filesWithRelPathPrepended];
}

- (void)createFilesWithContents:(NSDictionary *)filesWithContents
{
    for (NSString *relFilePath in filesWithContents)
    {
        [self createIntermediateDirectoriesForFilPath:relFilePath];

        NSData *content = filesWithContents[relFilePath];
        NSString *fullPathForFile = [self fullPathForFile:relFilePath];

        NSError *error;
        XCTAssertTrue([content writeToFile:fullPathForFile options:NSDataWritingAtomic error:&error],
                              @"Could not create file \"%@\", error: %@", fullPathForFile, error);
    }
}

- (void)createIntermediateDirectoriesForFilPath:(NSString *)relPath
{
    NSString *fullPathForFile = [self fullPathForFile:relPath];

    NSString *dirPath = [fullPathForFile stringByDeletingLastPathComponent];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *errorCreateDir;
    if (![fileManager createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:&errorCreateDir])
    {
        XCTFail(@"Could not create intermediate directories for file \"%@\" with error %@", fullPathForFile, errorCreateDir);
    }
}

- (void)createProjectSettingsFileWithName:(NSString *)name
{
    ProjectSettings *projectSettings = [[ProjectSettings alloc] init];
    projectSettings.projectPath = [_testDirecotoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.ccbproj", name]];
    XCTAssertTrue([projectSettings store], @"Could not create project file at \"%@\"", projectSettings.projectPath);
}

- (void)copyTestingResource:(NSString *)resourceName toFolder:(NSString *)folder
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *path = [bundle pathForResource:resourceName ofType:nil];

    NSString *fullTargetPath = [[self fullPathForFile:folder] stringByAppendingPathComponent:resourceName];

    [self createIntermediateDirectoriesForFilPath:fullTargetPath];

    [[NSFileManager defaultManager] copyItemAtPath:path toPath:fullTargetPath error:nil];
}

- (void)setModificationTime:(NSDate *)date forFiles:(NSArray *)files
{
    for (NSString *filePath in files)
    {
        NSString *fullFilePath = [self fullPathForFile:filePath];

        NSDictionary *attr = @{NSFileModificationDate : date};
        [[NSFileManager defaultManager] setAttributes:attr ofItemAtPath:fullFilePath error:NULL];
    }
}

- (NSDate *)modificationDateOfFile:(NSString *)filePath
{
    NSString *fullFilePath = [self fullPathForFile:filePath];
    NSDictionary* attr = [[NSFileManager defaultManager] attributesOfItemAtPath:fullFilePath error:NULL];
    return [attr objectForKey:NSFileModificationDate];
}

- (void)assertFileExists:(NSString *)filePath
{
    NSString *fullPath = [self fullPathForFile:filePath];
    XCTAssertTrue([_fileManager fileExistsAtPath:fullPath], @"File does not exist at \"%@\"", fullPath);
}

- (void)assertFilesExistRelativeToDirectory:(NSString *)relativeDirectoy filesPaths:(NSArray *)filePaths
{
    for (NSString *filePath in filePaths)
    {
        [self assertFileExists:[relativeDirectoy stringByAppendingPathComponent:filePath]];
    }
}

- (void)assertFileDoesNotExist:(NSString *)filePath
{
    NSString *fullPath = [self fullPathForFile:filePath];
    XCTAssertFalse([_fileManager fileExistsAtPath:fullPath], @"File exists at \"%@\"", fullPath);
}

- (void)assertFilesDoNotExistRelativeToDirectory:(NSString *)relativeDirectoy filesPaths:(NSArray *)filePaths;
{
    for (NSString *filePath in filePaths)
    {
        [self assertFileDoesNotExist:[relativeDirectoy stringByAppendingPathComponent:filePath]];
    }
}

- (NSString *)fullPathForFile:(NSString *)filePath
{
    if (![filePath hasPrefix:_testDirecotoryPath])
    {
        return [_testDirecotoryPath stringByAppendingPathComponent:filePath];
    }
    return filePath;
}

@end