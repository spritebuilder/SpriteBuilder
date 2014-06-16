//
//  PackageImporter_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 16.06.14.
//
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "ObserverTestHelper.h"
#import "NSString+Packages.h"
#import "NotificationNames.h"
#import "SBErrors.h"
#import "ProjectSettings.h"
#import "PackageCreateDelegateProtocol.h"
#import "PackageImporter.h"

@interface PackageImporter_Tests : XCTestCase

@end

@implementation PackageImporter_Tests
{
    PackageImporter *_packageImporter;
    ProjectSettings *_projectSettings;
    id _fileManagerMock;
}

- (void)setUp
{
    [super setUp];

    _packageImporter = [[PackageImporter alloc] init];

    _projectSettings = [[ProjectSettings alloc] init];
    _projectSettings.projectPath = @"/packagestests.ccbproj";
    _packageImporter.projectSettings = _projectSettings;

    _fileManagerMock = [OCMockObject niceMockForClass:[NSFileManager class]];
    _packageImporter.fileManager = _fileManagerMock;
}

- (void)testImportPackageWithName
{
    NSError *error;
    XCTAssertTrue([_packageImporter importPackageWithName:@"foo" error:&error]);
    XCTAssertNil(error);
}

// One package is addable
// The other one already is in the project
- (void)testImportPackagesWithTwoPackages
{
    id observerMock = [ObserverTestHelper observerMockForNotification:RESOURCE_PATHS_CHANGED];

    NSString *packagePathNotInProject = [@"/notYetInProject" stringByAppendingPackageSuffix];
    NSString *packagePathInProject = [@"/alreadyInProject" stringByAppendingPackageSuffix];
    NSArray *packagePaths = @[packagePathNotInProject, packagePathInProject];

    [_projectSettings addResourcePath:packagePathInProject error:nil];

    NSError *error;
    XCTAssertFalse([_packageImporter importPackagesWithPaths:packagePaths error:&error]);
    XCTAssertNotNil(error);

    NSArray *errors = error.userInfo[@"errors"];
    XCTAssertEqual(errors.count, 1);
    XCTAssertEqual(error.code, SBImportingPackagesError);

    [ObserverTestHelper verifyAndRemoveObserverMock:observerMock];
}

- (void)testImportPackageSuccessfully
{
    id observerMock = [ObserverTestHelper observerMockForNotification:RESOURCE_PATHS_CHANGED];

    NSString *packagePath = [@"/package/foo" stringByAppendingPackageSuffix];

    NSError *error;
    XCTAssertTrue([_packageImporter importPackagesWithPaths:@[packagePath] error:&error]);
    XCTAssertNil(error);

    [ObserverTestHelper verifyAndRemoveObserverMock:observerMock];
}

- (void)testImportPackageWithPathNotHavingPackageSuffix
{
    id observerMock = [ObserverTestHelper observerMockForNotification:RESOURCE_PATHS_CHANGED];

    NSString *packagePath = [@"/package/foo" stringByAppendingPackageSuffix];

    NSError *error;
    XCTAssertTrue([_packageImporter importPackagesWithPaths:@[packagePath] error:&error]);
    XCTAssertNil(error);

    [ObserverTestHelper verifyAndRemoveObserverMock:observerMock];
}

- (void)testImportPackageWithPathsExitIfNilOrEmptyArrayParam
{
    NSError *error1;
    XCTAssertTrue([_packageImporter importPackagesWithPaths:nil error:&error1]);
    XCTAssertNil(error1);

    NSError *error2;
    XCTAssertTrue([_packageImporter importPackagesWithPaths:@[] error:&error2]);
    XCTAssertNil(error2);
}

@end
