//
//  MoveFileCommand_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 25.06.14.
//
//

#import <XCTest/XCTest.h>

#import "FileSystemTestCase.h"
#import "MoveFileCommand.h"

@interface MoveFileCommand_Tests : FileSystemTestCase

@end


@implementation MoveFileCommand_Tests

- (void)testMoveFileCommand
{
    [self createFolders:@[@"anotherplace"]];
    [self createEmptyFiles:@[@"oneplace/important.txt"]];

    MoveFileCommand *moveFileCommand = [[MoveFileCommand alloc] initWithFromPath:[self fullPathForFile:@"oneplace/important.txt"]
                                                                          toPath:[self fullPathForFile:@"anotherplace/important.txt"]];

    NSError *error;
    XCTAssertTrue([moveFileCommand execute:&error], @"Move file command failed with error: %@", error);
    XCTAssertNil(error);

    [self assertFileExists:@"anotherplace/important.txt"];
    [self assertFileDoesNotExist:@"oneplace/important.txt"];
}

- (void)testMoveFileAndUndo
{
    [self createFolders:@[@"anotherplace"]];
    [self createEmptyFiles:@[@"oneplace/important.txt"]];

    MoveFileCommand *moveFileCommand = [[MoveFileCommand alloc] initWithFromPath:[self fullPathForFile:@"oneplace/important.txt"]
                                                                          toPath:[self fullPathForFile:@"anotherplace/important.txt"]];

    NSError *error;
    XCTAssertTrue([moveFileCommand execute:&error], @"Move file command failed with error: %@", error);
    XCTAssertNil(error);

    NSError *error2;
    XCTAssertTrue([moveFileCommand undo:&error], @"Move file command  UNDO failed with error: %@", error2);
    XCTAssertNil(error2);

    [self assertFileExists:@"oneplace/important.txt"];
    [self assertFileDoesNotExist:@"anotherplace/important.txt"];
}

- (void)testMoveFileFailsNoFile
{
    MoveFileCommand *moveFileCommand = [[MoveFileCommand alloc] initWithFromPath:[self fullPathForFile:@"oneplace/important.txt"]
                                                                           toPath:[self fullPathForFile:@"anotherplace/important.txt"]];

    NSError *error;
    XCTAssertFalse([moveFileCommand execute:&error], @"Move file command succeeded although it shouldn't have.");
    XCTAssertNotNil(error);
}

@end
