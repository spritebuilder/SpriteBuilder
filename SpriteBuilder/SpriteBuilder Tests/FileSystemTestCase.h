#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

@interface FileSystemTestCase : XCTestCase

@property (nonatomic, copy, readonly) NSString *testDirecotoryPath;
@property (nonatomic, strong) NSFileManager *fileManager;

- (void)createFolders:(NSArray *)folders;
- (void)createEmptyFiles:(NSArray *)files;
- (void)createProjectSettingsFileWithName:(NSString *)name;

- (NSDate *)modificationDateOfFile:(NSString *)filePath;
- (void)setModificationTime:(NSDate *)date forFiles:(NSArray *)files;

- (void)assertFileExists:(NSString *)filePath;
- (void)assertFileDoesNotExists:(NSString *)filePath;

// Will prepend the test directory's path if it's not already in the filePath.
// So anything that is not within the test directory is treated as a relative path to it.
// Example: Test dir is /foo/baa. A given relative filePath like 123/test.txt will turn into
// /foo/baa/123/test.txt
- (NSString *)fullPathForFile:(NSString *)filePath;

@end