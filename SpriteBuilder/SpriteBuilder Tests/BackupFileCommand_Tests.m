//
//  BackupFileCommand_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 11.02.15.
//
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "FileSystemTestCase.h"
#import "BackupFileCommand.h"
#import "Errors.h"

@interface BackupFileCommand_Tests : FileSystemTestCase

@end

@implementation BackupFileCommand_Tests

- (void)testBackupFileAndUndo
{
    [self createFilesWithContents:@{ @"foo.txt" : @"original" }];

    BackupFileCommand *backupFileCommand = [[BackupFileCommand alloc] initWithFilePath:[self fullPathForFile:@"foo.txt"]];

    NSError *error;
    XCTAssertFalse(backupFileCommand.executed);
    XCTAssertFalse(backupFileCommand.undone);

    XCTAssertTrue([backupFileCommand execute:&error]);
    XCTAssertTrue(backupFileCommand.executed);

    NSString *backupFilePath = [backupFileCommand.backupFilePath copy];

    [self assertContentsOfFilesEqual:@{ backupFileCommand.backupFilePath : @"original" }];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:[self fullPathForFile:@"foo.txt"] error:nil];
    [self assertFileDoesNotExist:@"foo.txt"];

    [self createFilesWithContents:@{ @"foo.txt" : @"replacement" }];

    NSError *undoError;
    XCTAssertTrue([backupFileCommand undo:&undoError]);
    XCTAssertNil(undoError);
    XCTAssertTrue(backupFileCommand.undone);

    [self assertFileExists:@"foo.txt"];

    [self assertContentsOfFilesEqual:@{ @"foo.txt" : @"original" }];

    XCTAssertFalse([fileManager fileExistsAtPath:backupFilePath]);
};

- (void)testBackupFolder
{
    [self createFilesWithContents:@{
        @"folder/foo.txt" : @"foo",
        @"folder/test/baa.txt" : @"baa"
    }];

    BackupFileCommand *backupFileCommand = [[BackupFileCommand alloc] initWithFilePath:[self fullPathForFile:@"folder"]];

    NSError *error;
    XCTAssertTrue([backupFileCommand execute:&error]);
    XCTAssertNil(error);

    NSFileManager *fileManager = [NSFileManager defaultManager];
    XCTAssertTrue([fileManager removeItemAtPath:[self fullPathForFile:@"folder"] error:nil]);

    NSError *undoError;
    XCTAssertTrue([backupFileCommand undo:&undoError]);
    XCTAssertNil(undoError);

    [self assertFilesExistRelativeToDirectory:@"folder" filesPaths:@[
            @"foo.txt",
            @"test/baa.txt",
    ]];

    [self assertContentsOfFilesEqual:@{
            @"folder/foo.txt" : @"foo",
            @"folder/test/baa.txt" : @"baa"
    }];
}

- (void)testExecutingTwice
{
    [self createEmptyFiles:@[@"test.txt"]];

    BackupFileCommand *backupFileCommand = [[BackupFileCommand alloc] initWithFilePath:[self fullPathForFile:@"test.txt"]];

    NSError *error;
    XCTAssertTrue([backupFileCommand execute:&error]);
    XCTAssertNil(error);

    NSError *error2;
    XCTAssertFalse([backupFileCommand execute:&error2]);
    XCTAssertNotNil(error2);
    XCTAssertEqual(error2.code, SBFileCommandBackupAlreadyExecutedError);
}

- (void)testTryingUndoButNoExecutedYet
{
    [self createEmptyFiles:@[@"test.txt"]];

    BackupFileCommand *backupFileCommand = [[BackupFileCommand alloc] initWithFilePath:[self fullPathForFile:@"test.txt"]];

    NSError *error;
    XCTAssertFalse([backupFileCommand undo:&error]);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, SBFileCommandBackupCannotUndoNonExecutedCommandError);
}

- (void)testUndoingTwice
{
    [self createEmptyFiles:@[@"test.txt"]];

    BackupFileCommand *backupFileCommand = [[BackupFileCommand alloc] initWithFilePath:[self fullPathForFile:@"test.txt"]];

    NSError *error;
    XCTAssertTrue([backupFileCommand execute:&error]);
    XCTAssertNil(error);

    NSError *error2;
    XCTAssertTrue([backupFileCommand undo:&error2]);
    XCTAssertNil(error2);

    NSError *error3;
    XCTAssertFalse([backupFileCommand undo:&error3]);
    XCTAssertNotNil(error3);
    XCTAssertEqual(error3.code, SBFileCommandBackupAlreadyUndoneError);
}

- (void)testBackupNonExistingFile
{
    BackupFileCommand *backupFileCommand = [[BackupFileCommand alloc] initWithFilePath:[self fullPathForFile:@"doesnotexist.txt"]];

    NSError *error;
    XCTAssertFalse([backupFileCommand execute:&error]);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, SBFileCommandBackupError);
}

- (void)testTidyUp
{
    [self createEmptyFiles:@[@"test.txt"]];

    BackupFileCommand *backupFileCommand = [[BackupFileCommand alloc] initWithFilePath:[self fullPathForFile:@"test.txt"]];

    NSError *error;
    XCTAssertTrue([backupFileCommand execute:&error]);
    XCTAssertNil(error);

    [backupFileCommand tidyUp];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    XCTAssertFalse([fileManager fileExistsAtPath:backupFileCommand.backupFilePath]);
}

@end
