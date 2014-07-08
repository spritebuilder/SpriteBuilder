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

@interface PackageCreator_Tests : XCTestCase

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
    _projectSettings.projectPath = @"/packagestests.ccbproj";
    _packageCreator.projectSettings = _projectSettings;

    _fileManagerMock = [OCMockObject niceMockForClass:[NSFileManager class]];
    _packageCreator.fileManager = _fileManagerMock;
}

- (void)testCreatePackageWithName
{
    NSString *fullPackagePath = [[@"/" stringByAppendingPathComponent:PACKAGES_FOLDER_NAME] stringByAppendingPathComponent:[@"NewPackage" stringByAppendingPackageSuffix]];

    [[[_fileManagerMock expect] andReturnValue:@(YES)] createDirectoryAtPath:fullPackagePath
                                                 withIntermediateDirectories:YES
                                                                  attributes:nil
                                                                       error:[OCMArg anyObjectRef]];
    NSError *error;
    XCTAssertTrue([_packageCreator createPackageWithName:@"NewPackage" error:&error], @"Creation of package should return YES.");
    XCTAssertNil(error, @"Error object should nil");

    [_fileManagerMock verify];
}

- (void)testCreatePackageFailsWithPackageAlreadyInProject
{
    NSString *fullPackagePath = [[@"/" stringByAppendingPathComponent:PACKAGES_FOLDER_NAME] stringByAppendingPathComponent:[@"NewPackage" stringByAppendingPackageSuffix]];

    [_projectSettings addResourcePath:fullPackagePath error:nil];

    [[[_fileManagerMock expect] andReturnValue:@(YES)] createDirectoryAtPath:fullPackagePath
                                                 withIntermediateDirectories:YES
                                                                  attributes:nil
                                                                       error:[OCMArg anyObjectRef]];

    NSError *error;
    XCTAssertFalse([_packageCreator createPackageWithName:@"NewPackage" error:&error], @"Creation of package should return NO.");
    XCTAssertNotNil(error, @"Error object should be set");
    XCTAssertEqual(error.code, SBDuplicateResourcePathError, @"Error code should equal constant SBDuplicateResourcePathError");
}

- (void)testCreatePackageFailsWithExistingPackageButNotInProject
{
    NSString *fullPackagePath = [[@"/" stringByAppendingPathComponent:PACKAGES_FOLDER_NAME] stringByAppendingPathComponent:[@"NewPackage" stringByAppendingPackageSuffix]];

    NSError *underlyingFileError = [NSError errorWithDomain:SBErrorDomain code:NSFileWriteFileExistsError userInfo:nil];
    [[[_fileManagerMock expect] andReturnValue:@(NO)] createDirectoryAtPath:fullPackagePath
                                                 withIntermediateDirectories:YES
                                                                  attributes:nil
                                                                       error:[OCMArg setTo:underlyingFileError]];

    NSError *error;
    XCTAssertFalse([_packageCreator createPackageWithName:@"NewPackage" error:&error], @"Creation of package should return NO.");
    XCTAssertNotNil(error, @"Error object should be set");
    XCTAssertEqual(error.code, SBResourcePathExistsButNotInProjectError, @"Error code should equal constant SBResourcePathExistsButNotInProjectError");

    [_fileManagerMock verify];
}

- (void)testCreatePackageFailsBecauseOfOtherDiskErrorThanFileExists
{
    NSString *fullPackagePath = [[@"/" stringByAppendingPathComponent:PACKAGES_FOLDER_NAME] stringByAppendingPathComponent:[@"NewPackage" stringByAppendingPackageSuffix]];

    NSError *underlyingFileError = [NSError errorWithDomain:SBErrorDomain code:NSFileWriteNoPermissionError userInfo:nil];
    [[[_fileManagerMock expect] andReturnValue:@(NO)] createDirectoryAtPath:fullPackagePath
                                                 withIntermediateDirectories:YES
                                                                  attributes:nil
                                                                       error:[OCMArg setTo:underlyingFileError]];

    NSError *error;
    XCTAssertFalse([_packageCreator createPackageWithName:@"NewPackage" error:&error], @"Creation of package should return NO.");
    XCTAssertNotNil(error, @"Error object should be set");
    XCTAssertEqual((int)error.code, NSFileWriteNoPermissionError, @"Error code should equal constant NSFileWriteNoPermissionError");

    [_fileManagerMock verify];
}

@end
