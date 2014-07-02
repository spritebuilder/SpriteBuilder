#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

@interface FileSystemTestCase : XCTestCase

@property (nonatomic, copy, readonly) NSString *testDirecotoryPath;
@property (nonatomic, strong) NSFileManager *fileManager;

- (void)createFolders:(NSArray *)folders;

- (void)createEmptyFiles:(NSArray *)files;

- (void)createProjectSettingsFileWithName:(NSString *)name;


- (void)setModificationTime:(NSDate *)date forFiles:(NSArray *)files;

- (NSDate *)modificationDateOfFile:(NSString *)filePath;

- (void)assertFileExists:(NSString *)filePath;

- (void)assertFileDoesNotExists:(NSString *)filePath;

- (NSString *)fullPathForFile:(NSString *)filePath;

@end