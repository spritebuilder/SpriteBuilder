#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

@class ProjectSettings;

@interface FileSystemTestCase : XCTestCase

@property (nonatomic, copy, readonly) NSString *testDirecotoryPath;
@property (nonatomic, strong) NSFileManager *fileManager;

- (void)createFolders:(NSArray *)folders;

// Will XCTFail if there was an error, just to keep code short
- (void)createIntermediateDirectoriesForFilPath:(NSString *)relPath;

// Will create empty text files at the given relativePaths in the array
// Containing folders have to exist
- (void)createEmptyFiles:(NSArray *)files;

// Creates files in bulk relative to a directory
// Example: relativeDir is foo/baa, and files are a/text.png and manual.txt
// file will be created at foo/baa/a/text.png and foo/baa/manual.txt
- (void)createEmptyFilesRelativeToDirectory:(NSString *)relativeDirectory files:(NSArray *)files;

// create files, dictionary structure: key: relativeFilePath
// value has to be of type NSData
// Example for parameter:
// NSDictionary *foo = @{@"path/to/file.txt": [NSData data]};
- (void)createFilesWithContents:(NSDictionary *)filesWithContents;

// Creates a .ccbproj file with default initialized values in testDirecotoryPath
// Returns an instance of the newly created project Setitngs
- (ProjectSettings *)createProjectSettingsFileWithName:(NSString *)name;

// asserts the contents of given files matches the given values
// Depending on the type of the value given the file is loaded as a certain class, supported: NSString, NSDictionary, NSArray, the rest is treated as NSData
// If a file does not exist the assertion will fail
// Example for parameter:
//   * NSDictionary *foo = @{@"path/to/image.png": [NSData data]};
//   * NSDictionary *foo = @{@"path/to/file.txt": @"hello"};
- (void)assertContentsOfFilesEqual:(NSDictionary *)filenameAndExpectation;

// asserts the contents of given files are not equal to the given values
// Depending on the type of the value given the file is loaded as a certain class, supported: NSString, NSDictionary, NSArray, the rest is treated as NSData
// If a file does not exist the assertion will fail
// Example for parameter:
//   * NSDictionary *foo = @{@"path/to/image.png": [NSData data]};
//   * NSDictionary *foo = @{@"path/to/file.txt": @"hello"};
- (void)assertContentsOfFilesNotEqual:(NSDictionary *)filenameAndExpectation;

- (NSDate *)modificationDateOfFile:(NSString *)filePath;
- (void)setModificationTime:(NSDate *)date forFiles:(NSArray *)files;

- (void)assertFileExists:(NSString *)filePath;
- (void)assertFilesExistRelativeToDirectory:(NSString *)relativeDirectoy filesPaths:(NSArray *)filePaths;

- (void)assertFileDoesNotExist:(NSString *)filePath;
- (void)assertFilesDoNotExistRelativeToDirectory:(NSString *)relativeDirectoy filesPaths:(NSArray *)filePaths;

// Will prepend the test directory's path if it's not already in the filePath.
// So anything that is not within the test directory is treated as a relative path to it.
// Example: Test dir is /foo/baa. A given relative filePath like 123/test.txt will turn into
// /foo/baa/123/test.txt
- (NSString *)fullPathForFile:(NSString *)filePath;

// Copies a resource in the bundle to the relative folder, the file's name will be preserved
// Add resource for the SB test target in the copy bundle phase of the xcode project settings
- (void)copyTestingResource:(NSString *)resourceName toFolder:(NSString *)folder;

// Copies a resource in the bundle to the relative path, add new filename
// Add resource for the SB test target in the copy bundle phase of the xcode project settings
- (void)copyTestingResource:(NSString *)resourceName toRelPath:(NSString *)toRelPath;

// This method will actually sort both arrays with the same sort descriptor and then compare so
// original ordering is not significant for comparison reasons.
- (void)assertArraysAreEqualIgnoringOrder:(NSArray *)arrayA arrayB:(NSArray *)arrayB;

// Works like XCTAssertEqualObjects but is intended to work with larger data structures or strings
// which will clutter your log if both objects are not the same. This method will only dump a diff to log.
- (void)assertEqualObjectsWithDiff:(id)objectA objectB:(id)objectB;

@end
