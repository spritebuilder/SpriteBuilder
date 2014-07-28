//
//  RemoveFileCommand_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 25.06.14.
//
//

#import <XCTest/XCTest.h>
#import "FileSystemTestCase.h"
#import "RemoveFileCommand.h"

@interface RemoveFileCommand_Tests : FileSystemTestCase

@end

@implementation RemoveFileCommand_Tests

- (void)testRemoveFile
{
    [self createEmptyFiles:@[@"foo/baa.txt"]];

    RemoveFileCommand *removeFileCommand = [[RemoveFileCommand alloc] initWithFilePath:[self fullPathForFile:@"foo"]];

    NSError *error;
    XCTAssertTrue([removeFileCommand execute:&error], @"Removing the file failed with error %@", error);
    XCTAssertNil(error);

    [self assertFileDoesNotExist:@"foo"];
}

- (void)testRemoveFileUndo
{
    [self createEmptyFiles:@[@"foo/baa.txt"]];

    RemoveFileCommand *removeFileCommand = [[RemoveFileCommand alloc] initWithFilePath:[self fullPathForFile:@"foo"]];

    NSError *error;
    XCTAssertTrue([removeFileCommand execute:&error], @"Removing the file failed with error %@", error);
    XCTAssertNil(error);

    NSError *error2;
    XCTAssertTrue([removeFileCommand undo:&error]);
    XCTAssertNil(error2);

    [self assertFileExists:@"foo/baa.txt"];
}

@end
