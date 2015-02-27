#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
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
        NSString *fullPathForFolder = [self fullPathForFile:relFolderPath];
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

        dictionary[relFilePath] = emptyStringData;
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

        id content = filesWithContents[relFilePath];
        NSString *fullPathForFile = [self fullPathForFile:relFilePath];

        if ([content isKindOfClass:[NSString class]])
        {
            NSError *error;
            XCTAssertTrue([content writeToFile:fullPathForFile atomically:YES encoding:NSUTF8StringEncoding error:&error], @"Error writing string: %@", error);
        }
        else
        {
            XCTAssertTrue([content writeToFile:fullPathForFile atomically:YES], @"Could not write file at '%@'", fullPathForFile);
        }
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

- (ProjectSettings *)createProjectSettingsFileWithName:(NSString *)name
{
    NSString *filename;
    if ([[name pathExtension] isEqualToString:@"ccbproj"] || [[name pathExtension] isEqualToString:@"sbproj"])
    {
        filename = name;
    }
    else
    {
        filename = [NSString stringWithFormat:@"%@.sbproj", name];
    }

    ProjectSettings *projectSettings = [[ProjectSettings alloc] init];
    projectSettings.projectPath = [_testDirecotoryPath stringByAppendingPathComponent:filename];

    [self createIntermediateDirectoriesForFilPath:projectSettings.projectPath];

    XCTAssertTrue([projectSettings store], @"Could not create project file at \"%@\"", projectSettings.projectPath);

    return projectSettings;
}

- (void)assertContentsOfFilesNotEqual:(NSDictionary *)filenameAndExpectation
{
    for (NSString *filePath in filenameAndExpectation)
    {
        NSError *error;
        id contentsOfFile = [self contentsOfFilePath:[self fullPathForFile:filePath] inferTypeFromData:filenameAndExpectation[filePath] error:&error];

        XCTAssertNotNil(contentsOfFile);
        XCTAssertNil(error);

        XCTAssertNotEqualObjects(filenameAndExpectation[filePath], contentsOfFile);
    }
}

- (void)assertContentsOfFilesEqual:(NSDictionary *)filenameAndExpectation
{
    for (NSString *filePath in filenameAndExpectation)
    {
        NSError *error;
        id contentsOfFile = [self contentsOfFilePath:[self fullPathForFile:filePath] inferTypeFromData:filenameAndExpectation[filePath] error:&error];

        XCTAssertNotNil(contentsOfFile);
        XCTAssertNil(error);

        [self assertEqualObjectsWithDiff:filenameAndExpectation[filePath] objectB:contentsOfFile];
    }
}

- (id)contentsOfFilePath:(NSString *)filepath inferTypeFromData:(id)data error:(NSError **)error
{
    if ([data isKindOfClass:[NSString class]])
    {
        return [NSString stringWithContentsOfFile:filepath encoding:NSUTF8StringEncoding error:error];
    }

    if ([data isKindOfClass:[NSDictionary class]])
    {
        return [NSDictionary dictionaryWithContentsOfFile:filepath];
    }

    if ([data isKindOfClass:[NSArray class]])
    {
        return [NSArray arrayWithContentsOfFile:filepath];
    }

    return [NSData dataWithContentsOfFile:[self fullPathForFile:filepath] options:0 error:error];
}

- (void)copyTestingResource:(NSString *)resourceName toRelPath:(NSString *)toRelPath
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *path = [bundle pathForResource:resourceName ofType:nil];

    NSString *fullTargetPath = [self fullPathForFile:toRelPath];

    [self createIntermediateDirectoriesForFilPath:fullTargetPath];

    [[NSFileManager defaultManager] copyItemAtPath:path toPath:fullTargetPath error:nil];
}

- (void)copyTestingResource:(NSString *)resourceName toFolder:(NSString *)folder
{
    NSString *fullTargetPath = [folder stringByAppendingPathComponent:resourceName];

    [self copyTestingResource:resourceName toRelPath:fullTargetPath];
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
    return attr[NSFileModificationDate];
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
    if ([filePath hasPrefix:@"/"])
    {
        return filePath;
    }

    if (![filePath hasPrefix:_testDirecotoryPath])
    {
        return [_testDirecotoryPath stringByAppendingPathComponent:filePath];
    }

    return filePath;
}

- (void)assertEqualObjectsWithDiff:(id)objectA objectB:(id)objectB
{
    BOOL equal = [objectA isEqualTo:objectB];
    XCTAssertTrue(equal);
    if (equal)
    {
        return;
    }

    NSTask *task = [[NSTask alloc] init];
    [task setCurrentDirectoryPath:NSTemporaryDirectory()];
    [task setLaunchPath:@"/bin/bash"];

    NSArray *args = @[@"-c", [NSString stringWithFormat:@"/usr/bin/diff <(echo \"%@\") <(echo \"%@\")", objectA, objectB]];
    [task setArguments:args];

    @try
    {
        [task launch];
        [task waitUntilExit];
    }
    @catch (NSException *exception)
    {
        NSLog(@"assertEqualObjectsWithDiff failed with exception %@", exception);
    }
}

- (void)assertArraysAreEqualIgnoringOrder:(NSArray *)arrayA arrayB:(NSArray *)arrayB
{
    NSMutableArray *arrayAMutable = [arrayA mutableCopy];
    NSMutableArray *arrayBMutable = [arrayB mutableCopy];

    NSSortDescriptor *highestToLowest = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:NO];
    [arrayAMutable sortUsingDescriptors:@[highestToLowest]];
    [arrayBMutable sortUsingDescriptors:@[highestToLowest]];

    XCTAssertEqualObjects(arrayAMutable, arrayBMutable);
}

@end
