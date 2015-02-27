//
//  PackageRemover_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 16.06.14.
//
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "ProjectSettings.h"
#import "ObserverTestHelper.h"
#import "NotificationNames.h"
#import "NSString+Packages.h"
#import "Errors.h"
#import "PackageRemover.h"
#import "RMPackage.h"
#import "MiscConstants.h"

@interface PackageRemover_Tests : XCTestCase

@end

@implementation PackageRemover_Tests
{
    PackageRemover *_packageRemover;
    ProjectSettings *_projectSettings;
    id _fileManagerMock;
}

- (void)setUp
{
    [super setUp];

    _packageRemover = [[PackageRemover alloc] init];

    _projectSettings = [[ProjectSettings alloc] init];

    _projectSettings.projectPath = @"/packagestests.ccbproj";
    _packageRemover.projectSettings = _projectSettings;

    _fileManagerMock = [OCMockObject niceMockForClass:[NSFileManager class]];
    _packageRemover.fileManager = _fileManagerMock;
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testRemovePackagesExitsWithoutErrorsForNilParamAndEmptyArray
{
    NSError *error1;
    XCTAssertTrue([_packageRemover removePackagesFromProject:nil error:&error1]);
    XCTAssertNil(error1);

    NSError *error2;
    XCTAssertTrue([_packageRemover removePackagesFromProject:@[] error:&error2]);
    XCTAssertNil(error2);

    [_fileManagerMock verify];
}

- (void)testRemovePackageSuccessfully
{
    id observerMock = [ObserverTestHelper observerMockForNotification:RESOURCE_PATHS_CHANGED];

    NSString *packagePath = [@"/package1" stringByAppendingPackageSuffix];
    [[[_fileManagerMock expect] andReturnValue:@(YES)] removeItemAtPath:packagePath error:[OCMArg anyObjectRef]];

    [_projectSettings addPackageWithFullPath:packagePath error:nil];

    RMPackage *packageToRemove = [[RMPackage alloc] init];
    packageToRemove.dirPath = packagePath;

    NSError *error;
    XCTAssertTrue([_packageRemover removePackagesFromProject:@[packageToRemove] error:&error]);
    XCTAssertNil(error);

    [ObserverTestHelper verifyAndRemoveObserverMock:observerMock];
    [_fileManagerMock verify];
}

- (void)testRemovePackagesWithAGoodAndOneErroneousPath
{
    id observerMockChanged = [ObserverTestHelper observerMockForNotification:RESOURCE_PATHS_CHANGED];

    RMPackage *packageWithGoodPath = [[RMPackage alloc] init];
    packageWithGoodPath.dirPath = [@"/goodPath" stringByAppendingPackageSuffix];

    RMPackage *packageWithBadPath = [[RMPackage alloc] init];
    packageWithBadPath.dirPath = [@"/badPath" stringByAppendingPackageSuffix];

    id observerMockRemoved = [ObserverTestHelper observerMockForNotification:RESOURCE_PATH_REMOVED
                                                              expectedObject:[OCMArg any]
                                                            expectedUserInfo:@{NOTIFICATION_USERINFO_KEY_FILEPATH : packageWithGoodPath.dirPath,
                                                                               NOTIFICATION_USERINFO_KEY_RESOURCE : packageWithGoodPath}];

    NSArray *packagesToBeRemoved = @[packageWithGoodPath, packageWithBadPath];

    [_projectSettings addPackageWithFullPath:packageWithGoodPath.dirPath error:nil];

    [[[_fileManagerMock expect] andReturnValue:@(YES)] removeItemAtPath:OCMOCK_ANY error:[OCMArg anyObjectRef]];

    NSError *error;
    XCTAssertFalse([_packageRemover removePackagesFromProject:packagesToBeRemoved error:&error]);
    XCTAssertNotNil(error);

    NSArray *errors = error.userInfo[@"errors"];
    XCTAssertEqual((int)errors.count, 1);
    XCTAssertEqual(error.code, SBRemovePackagesError);

    [ObserverTestHelper verifyAndRemoveObserverMock:observerMockChanged];
    [ObserverTestHelper verifyAndRemoveObserverMock:observerMockRemoved];
    [_fileManagerMock verify];
}

@end
