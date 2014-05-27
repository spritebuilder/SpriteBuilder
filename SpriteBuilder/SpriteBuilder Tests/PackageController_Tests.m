//
//  PackageController_Test.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 26.05.14.
//
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <objc/runtime.h>
#import "PackageCreateDelegateProtocol.h"
#import "PackageController.h"
#import "ProjectSettings.h"
#import "SBErrors.h"
#import "SnapLayerKeys.h"


@interface PackageController_Tests : XCTestCase

@end

@implementation PackageController_Tests
{
    PackageController *_packageController;
    id _projectSettingsMock;
    id _fileManagerMock;
}

- (void)setUp
{
    [super setUp];

    _packageController = [[PackageController alloc] init];

    _projectSettingsMock = [OCMockObject mockForClass:[ProjectSettings class]];
    _packageController.projectSettings = _projectSettingsMock;

    _fileManagerMock = [OCMockObject mockForClass:[NSFileManager class]];
    _packageController.fileManager = _fileManagerMock;
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testRemovePackagesExitsWithoutErrorsForNilParamAndEmptyArray
{
    NSError *error1;
    XCTAssertTrue([_packageController removePackagesFromProject:nil error:&error1]);
    XCTAssertNil(error1);

    NSError *error2;
    XCTAssertTrue([_packageController removePackagesFromProject:@[] error:&error2]);
    XCTAssertNil(error2);
}

- (void)testRemovePackageSuccessfully
{
    id observerMock = [OCMockObject observerMock];
    [[NSNotificationCenter defaultCenter] addMockObserver:observerMock name:RESOURCE_PATHS_CHANGED object:nil];
    [[observerMock expect] notificationWithName:RESOURCE_PATHS_CHANGED object:[OCMArg any]];

    NSString *packagePath = @"/package1";

    [[[_projectSettingsMock expect] andReturnValue:@(YES)] removeResourcePath:packagePath error:[OCMArg anyObjectRef]];

    NSError *error;
    XCTAssertTrue([_packageController removePackagesFromProject:@[packagePath] error:&error]);
    XCTAssertNil(error);

    [observerMock verify];
    [[NSNotificationCenter defaultCenter] removeObserver:observerMock];
}

- (void)testRemovePackagesWithAGoodAndOneErroneousPath
{
    id observerMock = [OCMockObject observerMock];
    [[NSNotificationCenter defaultCenter] addMockObserver:observerMock name:RESOURCE_PATHS_CHANGED object:nil];
    [[observerMock expect] notificationWithName:RESOURCE_PATHS_CHANGED object:[OCMArg any]];

    NSString *packagePathGood = @"/goodPath";
    NSString *packagePathBad = @"/badPath";
    NSArray *packagePaths = @[packagePathGood, packagePathBad];

    [[[_projectSettingsMock expect] andReturnValue:@(YES)] removeResourcePath:packagePathGood error:[OCMArg anyObjectRef]];
    NSError *underlyingRemoveError = [NSError errorWithDomain:SBErrorDomain code:SBResourcePathNotInProject userInfo:nil];
    [[[_projectSettingsMock expect] andReturnValue:@(NO)] removeResourcePath:packagePathBad  error:[OCMArg setTo:underlyingRemoveError]];

    NSError *error;
    XCTAssertFalse([_packageController removePackagesFromProject:packagePaths error:&error]);
    XCTAssertNotNil(error);

    NSArray *errors = error.userInfo[@"errors"];
    XCTAssertEqual(errors.count, 1);

    [observerMock verify];
    [[NSNotificationCenter defaultCenter] removeObserver:observerMock];
}

- (void)testCreatePackageWithName
{
    [[[_projectSettingsMock expect] andReturn:@"/"] projectPathDir];
    [[[_projectSettingsMock expect] andReturnValue:@(NO)] isResourcePathAlreadyInProject:@"/NewPackage.sbpack"];
    [[[_projectSettingsMock expect] andReturnValue:@(YES)] addResourcePath:@"/NewPackage.sbpack" error:[OCMArg anyObjectRef]];

    [[[_fileManagerMock expect] andReturnValue:@(YES)] createDirectoryAtPath:@"/NewPackage.sbpack"
                                                 withIntermediateDirectories:NO
                                                                  attributes:nil
                                                                       error:[OCMArg anyObjectRef]];
    NSError *error;
    XCTAssertTrue([_packageController createPackageWithName:@"NewPackage" error:&error], @"Creation of package should return YES.");
    XCTAssertNil(error, @"Error object should nil");

    [_projectSettingsMock verify];
    [_fileManagerMock verify];
}

- (void)testCreatePackageFailsWithPackageAlreadyInProject
{
    [[[_projectSettingsMock expect] andReturn:@"/"] projectPathDir];
    [[[_projectSettingsMock expect] andReturnValue:@(YES)] isResourcePathAlreadyInProject:@"/NewPackage.sbpack"];

    NSError *error;
    XCTAssertFalse([_packageController createPackageWithName:@"NewPackage" error:&error], @"Creation of package should return NO.");
    XCTAssertNotNil(error, @"Error object should be set");
    XCTAssertEqual(error.code, SBDuplicateResourcePathError, @"Error code should equal constant SBDuplicateResourcePathError");

    [_projectSettingsMock verify];
}

- (void)testCreatePackageFailsWithExistingPackageButNotInProject
{
    [[[_projectSettingsMock expect] andReturn:@"/"] projectPathDir];
    [[[_projectSettingsMock expect] andReturnValue:@(NO)] isResourcePathAlreadyInProject:@"/NewPackage.sbpack"];

    NSError *underlyingFileError = [NSError errorWithDomain:SBErrorDomain code:NSFileWriteFileExistsError userInfo:nil];
    [[[_fileManagerMock expect] andReturnValue:@(NO)] createDirectoryAtPath:@"/NewPackage.sbpack"
                                                 withIntermediateDirectories:NO
                                                                  attributes:nil
                                                                       error:[OCMArg setTo:underlyingFileError]];

    NSError *error;
    XCTAssertFalse([_packageController createPackageWithName:@"NewPackage" error:&error], @"Creation of package should return NO.");
    XCTAssertNotNil(error, @"Error object should be set");
    XCTAssertEqual(error.code, SBResourcePathExistsButNotInProjectError, @"Error code should equal constant SBResourcePathExistsButNotInProjectError");

    [_projectSettingsMock verify];
    [_fileManagerMock verify];
}

- (void)testCreatePackageFailsBecauseOfOtherDiskErrorThanFileExists
{
    [[[_projectSettingsMock expect] andReturn:@"/"] projectPathDir];
    [[[_projectSettingsMock expect] andReturnValue:@(NO)] isResourcePathAlreadyInProject:@"/NewPackage.sbpack"];

    NSError *underlyingFileError = [NSError errorWithDomain:SBErrorDomain code:NSFileWriteNoPermissionError userInfo:nil];
    [[[_fileManagerMock expect] andReturnValue:@(NO)] createDirectoryAtPath:@"/NewPackage.sbpack"
                                                 withIntermediateDirectories:NO
                                                                  attributes:nil
                                                                       error:[OCMArg setTo:underlyingFileError]];

    NSError *error;
    XCTAssertFalse([_packageController createPackageWithName:@"NewPackage" error:&error], @"Creation of package should return NO.");
    XCTAssertNotNil(error, @"Error object should be set");
    XCTAssertEqual(error.code, NSFileWriteNoPermissionError, @"Error code should equal constant NSFileWriteNoPermissionError");

    [_projectSettingsMock verify];
    [_fileManagerMock verify];
}

@end
