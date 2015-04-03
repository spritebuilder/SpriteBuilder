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
#import "Errors.h"
#import "NSString+Packages.h"
#import "MiscConstants.h"
#import "PackageCreator.h"
#import "FileSystemTestCase.h"

@interface PackageCreator_Tests : FileSystemTestCase

@property (nonatomic, strong) PackageCreator *packageCreator;
@property (nonatomic, strong) ProjectSettings *projectSettings;
@property (nonatomic, strong) id fileManagerMock;

@end

@implementation PackageCreator_Tests

- (void)setUp
{
    [super setUp];

    self.projectSettings = [[ProjectSettings alloc] init];
    self.projectSettings.projectPath = [self fullPathForFile:@"foo.spritebuilder/packagestests.ccbproj"];

    self.packageCreator = [[PackageCreator alloc] init];
    _packageCreator.projectSettings = _projectSettings;

    [self createFolders:@[@"foo.spritebuilder/Packages"]];
}

- (void)testCreatePackageWithName
{
    NSError *error;
    XCTAssertEqualObjects([_packageCreator createPackageWithName:@"NewPackage" error:&error], [self fullPathForFile:@"foo.spritebuilder/Packages/NewPackage.sbpack"]);
    XCTAssertNil(error, @"Error object should nil");

    [self assertFileExists:@"foo.spritebuilder/Packages/NewPackage.sbpack"];
    [self assertFileExists:@"foo.spritebuilder/Packages/NewPackage.sbpack/Package.plist"];

    XCTAssertTrue([_projectSettings isPackageWithFullPathInProject:[self fullPathForFile:@"foo.spritebuilder/Packages/NewPackage.sbpack"]]);
}

- (void)testCreatePackageFailsWithPackageAlreadyInProject
{
    NSString *fullPackagePath = [self fullPathForFile:@"foo.spritebuilder/Packages/NewPackage.sbpack"];

    [_projectSettings addPackageWithFullPath:fullPackagePath error:nil];

    NSError *error;
    XCTAssertNil([_packageCreator createPackageWithName:@"NewPackage" error:&error], @"Creation of package should return NO.");
    XCTAssertNotNil(error, @"Error object should be set");
    XCTAssertEqual(error.code, SBDuplicatePackageError, @"Error code should equal constant SBDuplicateResourcePathError");
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
    XCTAssertEqual(error.code, SBPackageExistsButNotInProjectError, @"Error code should equal constant SBResourcePathExistsButNotInProjectError");

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
    [_projectSettings addPackageWithFullPath:[self fullPathForFile:@"foo.spritebuilder/Packages/NewPackage.sbpack"] error:nil];
    [_projectSettings addPackageWithFullPath:[self fullPathForFile:@"foo.spritebuilder/Packages/NewPackage 1.sbpack"] error:nil];
    [self createFolders:@[@"foo.spritebuilder/Packages/NewPackage 2.sbpack"]];

    XCTAssertEqualObjects(@"NewPackage 3", [_packageCreator creatablePackageNameWithBaseName:@"NewPackage"]);
}

@end
