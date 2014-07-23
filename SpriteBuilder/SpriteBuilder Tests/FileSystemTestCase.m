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
    for (NSString *relFilePath in files)
    {
        NSString *fullPathForFile = [_testDirecotoryPath stringByAppendingPathComponent:relFilePath];
        NSError *error;
        XCTAssertTrue([@"" writeToFile:fullPathForFile atomically:YES encoding:NSUTF8StringEncoding error:&error],
                      @"Could not create file \"%@\", error: %@", fullPathForFile, error);
    }
}

- (void)createProjectSettingsFileWithName:(NSString *)name
{
    ProjectSettings *projectSettings = [[ProjectSettings alloc] init];
    projectSettings.projectPath = [_testDirecotoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.ccbproj", name]];
    XCTAssertTrue([projectSettings store], @"Could not create project file at \"%@\"", projectSettings.projectPath);
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

- (void)assertFileDoesNotExists:(NSString *)filePath
{
    NSString *fullPath = [self fullPathForFile:filePath];
    XCTAssertFalse([_fileManager fileExistsAtPath:fullPath], @"File exists at \"%@\"", fullPath);
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