//
//  CreateDirectoryFileCommand.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 25.06.14.
//
//

#import <XCTest/XCTest.h>
#import "FileSystemTestCase.h"
#import "CreateDirectoryFileCommand.h"

@interface CreateDirectoryFileCommand_Tests : FileSystemTestCase

@end

@implementation CreateDirectoryFileCommand_Tests

- (void)testCreationOfDirectory
{
    NSString *dirToCreatePath = [self fullPathForFile:@"new"];

    CreateDirectoryFileCommand *createDirectoryFileCommand = [[CreateDirectoryFileCommand alloc] initWithDirPath:dirToCreatePath];

    NSError *error;
    XCTAssertTrue([createDirectoryFileCommand execute:&error], @"Creation of directory failed with error %@", error);
    XCTAssertNil(error);

    [self assertFileExists:@"new"];
}

- (void)testUndo
{
    NSString *dirToCreatePath = [self fullPathForFile:@"new"];

    CreateDirectoryFileCommand *createDirectoryFileCommand = [[CreateDirectoryFileCommand alloc] initWithDirPath:dirToCreatePath];

    NSError *error;
    XCTAssertTrue([createDirectoryFileCommand execute:&error], @"Creation of directory failed with error %@", error);
    XCTAssertNil(error);

    NSError *error2;
    XCTAssertTrue([createDirectoryFileCommand undo:&error], @"Creation of directory failed with error %@", error2);
    XCTAssertNil(error2);

    [self assertFileDoesNotExist:@"new"];
}

@end
