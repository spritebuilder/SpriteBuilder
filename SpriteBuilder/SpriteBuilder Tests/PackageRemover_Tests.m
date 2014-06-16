//
//  PackageRemover_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 16.06.14.
//
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "PackageCreateDelegateProtocol.h"
#import "PackageController.h"
#import "ProjectSettings.h"
#import "ObserverTestHelper.h"
#import "NotificationNames.h"
#import "NSString+Packages.h"
#import "SBErrors.h"

@interface PackageRemover_Tests : XCTestCase

@end

@implementation PackageRemover_Tests
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
    id observerMock = [ObserverTestHelper observerMockForNotification:RESOURCE_PATHS_CHANGED];

    NSString *packagePath = [@"/package1" stringByAppendingPackageSuffix];

    [_projectSettings addResourcePath:packagePath error:nil];

    NSError *error;
    XCTAssertTrue([_packageController removePackagesFromProject:@[packagePath] error:&error]);
    XCTAssertNil(error);

    [ObserverTestHelper verifyAndRemoveObserverMock:observerMock];
}

- (void)testRemovePackagesWithAGoodAndOneErroneousPath
{
    id observerMock = [ObserverTestHelper observerMockForNotification:RESOURCE_PATHS_CHANGED];

    NSString *packagePathGood = [@"/goodPath" stringByAppendingPackageSuffix];
    NSString *packagePathBad = [@"/badPath" stringByAppendingPackageSuffix];
    NSArray *packagePaths = @[packagePathGood, packagePathBad];

    [_projectSettings addResourcePath:packagePathGood error:nil];

    NSError *error;
    XCTAssertFalse([_packageController removePackagesFromProject:packagePaths error:&error]);
    XCTAssertNotNil(error);

    NSArray *errors = error.userInfo[@"errors"];
    XCTAssertEqual(errors.count, 1);
    XCTAssertEqual(error.code, SBRemovePackagesError);

    [ObserverTestHelper verifyAndRemoveObserverMock:observerMock];
}

@end
