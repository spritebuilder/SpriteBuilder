//
//  PackageExporter_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 16.06.14.
//
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "ProjectSettings.h"
#import "PackageCreateDelegateProtocol.h"
#import "PackageController.h"
#import "SBErrors.h"
#import "NSString+Packages.h"
#import "RMPackage.h"

@interface PackageExporter_Tests : XCTestCase

@end

@implementation PackageExporter_Tests
{
    PackageController *_packageController;
    ProjectSettings *_projectSettings;
    id _fileManagerMock;
}

- (void)setUp
{
    [super setUp];

    _packageController = [[PackageController alloc] init];

    _projectSettings = [[ProjectSettings alloc] init];
    _projectSettings.projectPath = @"/packagestests.ccbproj";
    _packageController.projectSettings = _projectSettings;

    _fileManagerMock = [OCMockObject niceMockForClass:[NSFileManager class]];
    _packageController.fileManager = _fileManagerMock;
}

- (void)testPackageExportWithExistingExportFolderAtDestination
{
    id mockFileManager = [OCMockObject mockForClass:[NSFileManager class]];
    _packageController.fileManager = mockFileManager;

    [[[mockFileManager expect] andReturnValue:@(YES)] fileExistsAtPath:OCMOCK_ANY];

    RMPackage *package = [[RMPackage alloc] init];
    package.dirPath = [@"/baa/foo" stringByAppendingPackageSuffix];

    NSError *error;
    XCTAssertFalse([_packageController exportPackage:package toPath:@"/foo" error:&error]);
    XCTAssertNotNil(error, @"Error object should be set");
    XCTAssertEqual(error.code, SBPackageAlreadyExistsAtPathError);

    [mockFileManager verify];
}

- (void)testPackageExport
{
    id mockFileManager = [OCMockObject mockForClass:[NSFileManager class]];
    _packageController.fileManager = mockFileManager;

    NSString *toPath = @"/foo";
    RMPackage *package = [[RMPackage alloc] init];
    package.dirPath = @"/baa/superpackage.sbpack";
    NSString *expectedCopyToPath = [@"/foo/superpackage" stringByAppendingPackageSuffix];

    [[[mockFileManager expect] andReturnValue:@(NO)] fileExistsAtPath:expectedCopyToPath];
    [[[mockFileManager expect] andReturnValue:@(YES)] copyItemAtPath:package.dirPath toPath:expectedCopyToPath error:[OCMArg anyObjectRef]];

    NSError *error;
    XCTAssertTrue([_packageController exportPackage:package toPath:toPath error:&error]);
    XCTAssertNil(error);
}

- (void)testPackageExportWithWrongInput
{
    id wrongPackage = @"I'm a package for sure!";
    NSError *error;

    XCTAssertFalse([_packageController exportPackage:wrongPackage toPath:@"/foo" error:&error]);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, SBPackageExportInvalidPackageError);
}

- (void)testPackageWithoutPath
{
    RMPackage *package = [[RMPackage alloc] init];
    NSError *error;

    XCTAssertFalse([_packageController exportPackage:package toPath:@"/foo" error:&error]);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, SBPackageExportInvalidPackageError);
}

@end
