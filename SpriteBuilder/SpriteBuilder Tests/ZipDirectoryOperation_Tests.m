//
//  ZipDirectoryOperation_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 21.07.14.
//
//

#import <XCTest/XCTest.h>
#import "FileSystemTestCase.h"
#import "ZipDirectoryOperation.h"
#import "CCBWarnings.h"
#import "ProjectSettings.h"

@interface ZipDirectoryOperation_Tests : FileSystemTestCase

@property (nonatomic, strong) ZipDirectoryOperation *operation;

@end


@implementation ZipDirectoryOperation_Tests

- (void)setUp
{
    [super setUp];

    [self createEmptyFiles:@[
            @"in/README.txt",
            @"in/doc/manual.md"
    ]];

    CCBWarnings *warnings = [[CCBWarnings alloc] init];
    ProjectSettings *projectSettings = [[ProjectSettings alloc] init];

    self.operation = [[ZipDirectoryOperation alloc] initWithProjectSettings:projectSettings
                                                                   warnings:warnings
                                                             statusProgress:nil];
    _operation.inputPath = [self fullPathForFile:@"in"];
}

- (void)testStandard
{
    _operation.zipOutputPath  = [self fullPathForFile:@"out.zip"];

    [_operation start];

    [self assertFileExists:@"out.zip"];
}

- (void)testOutputPathWithoutExtension
{
    _operation.zipOutputPath  = [self fullPathForFile:@"out"];

    [_operation start];

    [self assertFileExists:@"out.zip"];
}

- (void)testWithoutOutputPath
{
    [_operation start];

    [self assertFileExists:@"in.zip"];
}

- (void)testWithExistingNonZipOutputFile
{
    [self createEmptyFiles:@[@"in.zip"]];

    NSDate *referenceMDate = [NSDate dateWithTimeIntervalSince1970:0];
    [self setModificationTime:referenceMDate forFiles:@[@"in.zip"]];

    [_operation start];

    NSDate *mdateOfFile = [self modificationDateOfFile:@"in.zip"];

    XCTAssertTrue([referenceMDate isEqualToDate:mdateOfFile]);
}

- (void)testCreateDirectories
{
    _operation.createDirectories = YES;

    [self createEmptyFiles:@[@"in.zip"]];

    _operation.zipOutputPath  = [self fullPathForFile:@"foo/baa/out.zip"];

    [_operation start];


    [self assertFileExists:@"foo/baa/out.zip"];
}

- (void)testWthoutCreateDirectories
{
    _operation.createDirectories = NO;

    [self createEmptyFiles:@[@"in.zip"]];

    _operation.zipOutputPath  = [self fullPathForFile:@"foo/baa/out.zip"];

    [_operation start];


    [self assertFileDoesNotExist:@"foo/baa/out.zip"];
}

@end
