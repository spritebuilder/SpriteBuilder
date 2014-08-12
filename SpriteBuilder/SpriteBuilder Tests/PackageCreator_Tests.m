//
//  PackageCreator_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 16.06.14.
//
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "ProjectSettings.h"
#import "SBErrors.h"
#import "NSString+Packages.h"
#import "MiscConstants.h"
#import "PackageCreator.h"
#import "FileSystemTestCase.h"
#import "SBAssserts.h"

@interface PackageCreator_Tests : FileSystemTestCase

@end

@implementation PackageCreator_Tests
{
    PackageCreator *_packageCreator;
    ProjectSettings *_projectSettings;
    id _fileManagerMock;
}

- (void)setUp
{
    [super setUp];

    _packageCreator = [[PackageCreator alloc] init];

    _projectSettings = [[ProjectSettings alloc] init];
    _projectSettings.projectPath = [self fullPathForFile:@"foo.spritebuilder/packagestests.ccbproj"];
    _packageCreator.projectSettings = _projectSettings;

    [self createFolders:@[@"foo.spritebuilder/Packages"]];
}

- (void)testCreatePackageWithName
{
    NSError *error;
    SBAssertStringsEqual([_packageCreator createPackageWithName:@"NewPackage" error:&error], [self fullPathForFile:@"foo.spritebuilder/Packages/NewPackage.sbpack"]);
    XCTAssertNil(error, @"Error object should nil");

    [self assertFileExists:@"foo.spritebuilder/Packages/NewPackage.sbpack"];
    [self assertFileExists:@"foo.spritebuilder/Packages/NewPackage.sbpack/Package.plist"];

    XCTAssertTrue([_projectSettings isResourcePathInProject:[self fullPathForFile:@"foo.spritebuilder/Packages/NewPackage.sbpack"]]);
}

- (void)testCreatePackageFailsWithPackageAlreadyInProject
{
    NSString *fullPackagePath = [self fullPathForFile:@"foo.spritebuilder/Packages/NewPackage.sbpack"];

    [_projectSettings addResourcePath:fullPackagePath error:nil];

    NSError *error;
    XCTAssertNil([_packageCreator createPackageWithName:@"NewPackage" error:&error], @"Creation of package should return NO.");
    XCTAssertNotNil(error, @"Error object should be set");
    XCTAssertEqual(error.code, SBDuplicateResourcePathError, @"Error code should equal constant SBDuplicateResourcePathError");
}

- (void)testCreatePackageFailsWithExistingPackageButNotInProject
{
    _fileManagerMock = [OCMockObject niceMockForClass:[NSFileManager class]];
    _packageCreator.fileManager = _fileManagerMock;

    NSString *fullPackagePath = [self fullPathForFile:@"foo.spritebuilder/Packages/NewPackage.sbpack"];

    NSError *underlyingFileError = [NSError errorWithDomain:SBErrorDomain code:NSFileWriteFileExistsError userInfo:nil];
    [[[_fileManagerMock expect] andReturnValue:@(NO)] createDirectoryAtPath:fullPackagePath
                                                 withIntermediateDirectories:YES
                                                                  attributes:nil
                                                                       error:[OCMArg setTo:underlyingFileError]];

    NSError *error;
    XCTAssertNil([_packageCreator createPackageWithName:@"NewPackage" error:&error], @"Creation of package should return NO.");
    XCTAssertNotNil(error, @"Error object should be set");
    XCTAssertEqual(error.code, SBResourcePathExistsButNotInProjectError, @"Error code should equal constant SBResourcePathExistsButNotInProjectError");

    [_fileManagerMock verify];
}

- (void)testCreatePackageFailsBecauseOfOtherDiskErrorThanFileExists
{
    _fileManagerMock = [OCMockObject niceMockForClass:[NSFileManager class]];
    _packageCreator.fileManager = _fileManagerMock;

    NSString *fullPackagePath = [self fullPathForFile:@"foo.spritebuilder/Packages/NewPackage.sbpack"];

    NSError *underlyingFileError = [NSError errorWithDomain:SBErrorDomain code:NSFileWriteNoPermissionError userInfo:nil];
    [[[_fileManagerMock expect] andReturnValue:@(NO)] createDirectoryAtPath:fullPackagePath
                                                 withIntermediateDirectories:YES
                                                                  attributes:nil
                                                                       error:[OCMArg setTo:underlyingFileError]];

    NSError *error;
    XCTAssertNil([_packageCreator createPackageWithName:@"NewPackage" error:&error], @"Creation of package should return NO.");
    XCTAssertNotNil(error, @"Error object should be set");
    XCTAssertEqual((int)error.code, NSFileWriteNoPermissionError, @"Error code should equal constant NSFileWriteNoPermissionError");

    [_fileManagerMock verify];
}

- (void)testCreatablePackageNameWithBaseName
{
    [_projectSettings addResourcePath:[self fullPathForFile:@"foo.spritebuilder/Packages/NewPackage.sbpack"] error:nil];
    [_projectSettings addResourcePath:[self fullPathForFile:@"foo.spritebuilder/Packages/NewPackage 1.sbpack"] error:nil];
    [self createFolders:@[@"foo.spritebuilder/Packages/NewPackage 2.sbpack"]];

    SBAssertStringsEqual(@"NewPackage 3", [_packageCreator creatablePackageNameWithBaseName:@"NewPackage"]);
}

@end
