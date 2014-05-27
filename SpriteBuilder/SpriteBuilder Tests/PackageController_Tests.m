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

- (void)testCreatePackageWithNameAlreadyInProject
{
    [[[_projectSettingsMock expect] andReturn:@"/"] projectPathDir];
    [[[_projectSettingsMock expect] andReturnValue:@(YES)] isResourcePathAlreadyInProject:@"/NewPackage.sbpack"];

    NSError *error;
    XCTAssertFalse([_packageController createPackageWithName:@"NewPackage" error:&error], @"Creation of package should return NO.");
    XCTAssertNotNil(error, @"Error object should be set");
    XCTAssertEqual(error.code, SBDuplicateResourcePathError, @"Error code should equal constant SBDuplicateResourcePathError");

    [_projectSettingsMock verify];
}

@end
