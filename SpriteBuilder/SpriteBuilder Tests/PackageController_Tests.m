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
#import "NotificationNames.h"
#import "MiscConstants.h"
#import "RMPackage.h"
#import "SBAssserts.h"
#import "ResourceManager.h"
#import "NSString+Packages.h"
#import "ObserverTestHelper.h"


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

    _projectSettingsMock = [OCMockObject niceMockForClass:[ProjectSettings class]];
    _packageController.projectSettings = _projectSettingsMock;

    _fileManagerMock = [OCMockObject niceMockForClass:[NSFileManager class]];
    _packageController.fileManager = _fileManagerMock;
}

- (void)tearDown
{
    [super tearDown];
}


- (void)testImportPackageWithName
{
    [[[_projectSettingsMock expect] andReturn:@"/"] projectPathDir];

    id packageControllerMock = [OCMockObject partialMockForObject:_packageController];

    NSString *expectedFullPath = [@"/foo" pathByAppendingPackageSuffix];

    [[[packageControllerMock expect] andReturnValue:@(YES)] importPackageWithPath:expectedFullPath error:[OCMArg anyObjectRef]];
    [[[packageControllerMock expect] andReturnValue:@(YES)] importPackagesWithPaths:[OCMArg checkWithSelector:@selector(isEqualToArray:) onObject:@[expectedFullPath]] error:[OCMArg anyObjectRef]];

    XCTAssertTrue([_packageController importPackageWithName:@"foo" error:nil]);

    [_projectSettingsMock verify];
}


- (void)testImportPackagesWithTwoPackages
{
    // One package is addable
    // The other one already is in the project

    id observerMock = [ObserverTestHelper observerMockForNotification:RESOURCE_PATHS_CHANGED];

    NSString *packagePathNotInProject = [@"/notYetInProject" pathByAppendingPackageSuffix];
    NSString *packagePathInProject = [@"/alreadyInProject" pathByAppendingPackageSuffix];
    NSArray *packagePaths = @[packagePathNotInProject, packagePathInProject];

    ProjectSettings *projectSettings = [[ProjectSettings alloc] init];
    [projectSettings addResourcePath:packagePathInProject error:nil];
    _packageController.projectSettings = projectSettings;

    NSError *error;
    XCTAssertFalse([_packageController importPackagesWithPaths:packagePaths error:&error]);
    XCTAssertNotNil(error);

    NSArray *errors = error.userInfo[@"errors"];
    XCTAssertEqual(errors.count, 1);
    XCTAssertEqual(error.code, SBImportingPackagesError);

    [ObserverTestHelper verifyAndRemoveObserverMock:observerMock];
}

- (void)testImportPackageSuccessfully
{
    NSString *packagePath = [@"/package/foo" pathByAppendingPackageSuffix];
    id observerMock = [ObserverTestHelper observerMockForNotification:RESOURCE_PATHS_CHANGED];

    ProjectSettings *projectSettings = [[ProjectSettings alloc] init];
    _packageController.projectSettings = projectSettings;

    NSError *error;
    XCTAssertTrue([_packageController importPackagesWithPaths:@[packagePath] error:&error]);
    XCTAssertNil(error);

    [self verifyAndRemoveObserverMock:observerMock];
}

- (void)testImportPackageWithPathsExitIfNilOrEmptyArrayParam
{
    NSError *error1;
    XCTAssertTrue([_packageController importPackagesWithPaths:nil error:&error1]);
    XCTAssertNil(error1);

    NSError *error2;
    XCTAssertTrue([_packageController importPackagesWithPaths:@[] error:&error2]);
    XCTAssertNil(error2);
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

    NSString *packagePath = [@"/package1" pathByAppendingPackageSuffix];

    [[[_projectSettingsMock expect] andReturnValue:@(YES)] removeResourcePath:packagePath error:[OCMArg anyObjectRef]];

    NSError *error;
    XCTAssertTrue([_packageController removePackagesFromProject:@[packagePath] error:&error]);
    XCTAssertNil(error);

    [ObserverTestHelper verifyAndRemoveObserverMock:observerMock];
}

- (void)testRemovePackagesWithAGoodAndOneErroneousPath
{
    id observerMock = [ObserverTestHelper observerMockForNotification:RESOURCE_PATHS_CHANGED];

    NSString *packagePathGood = [@"/goodPath" pathByAppendingPackageSuffix];
    NSString *packagePathBad = [@"/badPath" pathByAppendingPackageSuffix];
    NSArray *packagePaths = @[packagePathGood, packagePathBad];

    [[[_projectSettingsMock expect] andReturnValue:@(YES)] removeResourcePath:packagePathGood error:[OCMArg anyObjectRef]];
    NSError *underlyingRemoveError = [NSError errorWithDomain:SBErrorDomain code:SBResourcePathNotInProjectError userInfo:nil];
    [[[_projectSettingsMock expect] andReturnValue:@(NO)] removeResourcePath:packagePathBad  error:[OCMArg setTo:underlyingRemoveError]];

    NSError *error;
    XCTAssertFalse([_packageController removePackagesFromProject:packagePaths error:&error]);
    XCTAssertNotNil(error);

    NSArray *errors = error.userInfo[@"errors"];
    XCTAssertEqual(errors.count, 1);
    XCTAssertEqual(error.code, SBRemovePackagesError);

    [ObserverTestHelper verifyAndRemoveObserverMock:observerMock];
}

- (void)testCreatePackageWithName
{
    [[[_projectSettingsMock expect] andReturn:@"/"] projectPathDir];
    [[[_projectSettingsMock expect] andReturnValue:@(NO)] isResourcePathInProject:[@"/NewPackage" pathByAppendingPackageSuffix]];
    [[[_projectSettingsMock expect] andReturnValue:@(YES)] addResourcePath:@"/NewPackage.sbpack" error:[OCMArg anyObjectRef]];

    [[[_fileManagerMock expect] andReturnValue:@(YES)] createDirectoryAtPath:[@"/NewPackage" pathByAppendingPackageSuffix]
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
    [[[_projectSettingsMock expect] andReturnValue:@(YES)] isResourcePathInProject:[@"/NewPackage" pathByAppendingPackageSuffix]];

    NSError *error;
    XCTAssertFalse([_packageController createPackageWithName:@"NewPackage" error:&error], @"Creation of package should return NO.");
    XCTAssertNotNil(error, @"Error object should be set");
    XCTAssertEqual(error.code, SBDuplicateResourcePathError, @"Error code should equal constant SBDuplicateResourcePathError");

    [_projectSettingsMock verify];
}

- (void)testCreatePackageFailsWithExistingPackageButNotInProject
{
    [[[_projectSettingsMock expect] andReturn:@"/"] projectPathDir];
    [[[_projectSettingsMock expect] andReturnValue:@(NO)] isResourcePathInProject:[@"/NewPackage" pathByAppendingPackageSuffix]];

    NSError *underlyingFileError = [NSError errorWithDomain:SBErrorDomain code:NSFileWriteFileExistsError userInfo:nil];
    [[[_fileManagerMock expect] andReturnValue:@(NO)] createDirectoryAtPath:[@"/NewPackage" pathByAppendingPackageSuffix]
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
    [[[_projectSettingsMock expect] andReturnValue:@(NO)] isResourcePathInProject:[@"/NewPackage" pathByAppendingPackageSuffix]];

    NSError *underlyingFileError = [NSError errorWithDomain:SBErrorDomain code:NSFileWriteNoPermissionError userInfo:nil];
    [[[_fileManagerMock expect] andReturnValue:@(NO)] createDirectoryAtPath:[@"/NewPackage" pathByAppendingPackageSuffix]
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

- (void)testPackageExportWithExistingExportFolderAtDestination
{
    id mockFileManager = [OCMockObject mockForClass:[NSFileManager class]];
    _packageController.fileManager = mockFileManager;

    [[[mockFileManager expect] andReturnValue:@(YES)] fileExistsAtPath:OCMOCK_ANY];

    RMPackage *package = [[RMPackage alloc] init];
    package.dirPath = [@"/baa/foo" pathByAppendingPackageSuffix];

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
    NSString *expectedCopyToPath = [@"/foo/superpackage" pathByAppendingPackageSuffix];

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

- (void)testCanRenamePackageWithExistingFullPathInProject
{
    RMPackage *package = [[RMPackage alloc] init];
    package.dirPath = [@"/project/pack_old" pathByAppendingPackageSuffix];

    [[[_projectSettingsMock expect] andReturnValue:@(YES)] isResourcePathInProject:[@"/project/pack_new" pathByAppendingPackageSuffix]];

    NSError *error;
    XCTAssertFalse([_packageController canRenamePackage:package toName:@"pack_new" error:&error]);
    XCTAssertEqual(error.code, SBDuplicateResourcePathError);

    [_projectSettingsMock verify];
}

- (void)testCanRenamePackageWithExistingFullPathInFileSystemButNotInProject
{
    RMPackage *package = [[RMPackage alloc] init];
    package.dirPath = [@"/project/pack_old" pathByAppendingPackageSuffix];

    [[[_fileManagerMock expect] andReturnValue:@(YES)] fileExistsAtPath:[@"/project/pack_new" pathByAppendingPackageSuffix]];
    [[[_projectSettingsMock expect] andReturnValue:@(NO)] isResourcePathInProject:OCMOCK_ANY];

    NSError *error;
    XCTAssertFalse([_packageController canRenamePackage:package toName:@"pack_new" error:&error]);
    XCTAssertEqual(error.code, SBResourcePathExistsButNotInProjectError);

    [_projectSettingsMock verify];
    [_fileManagerMock verify];
}

- (void)testCanRenamePackage
{
    RMPackage *package = [[RMPackage alloc] init];
    package.dirPath = [@"/project/pack_old" pathByAppendingPackageSuffix];

    [[[_fileManagerMock expect] andReturnValue:@(NO)] fileExistsAtPath:OCMOCK_ANY];
    [[[_projectSettingsMock expect] andReturnValue:@(NO)] isResourcePathInProject:@"/project/pack_new.sbpack"];

    XCTAssertTrue([_packageController canRenamePackage:package toName:@"pack_new" error:nil]);

    [_projectSettingsMock verify];
    [_fileManagerMock verify];
}

- (void)testCanRenamePackageWithNoChange
{
    RMPackage *package = [[RMPackage alloc] init];
    package.dirPath = [@"/project/pack_old" pathByAppendingPackageSuffix];

    XCTAssertTrue([_packageController canRenamePackage:package toName:package.dirPath error:nil]);
}

- (void)testRenamePackage
{
    RMPackage *package = [[RMPackage alloc] init];
    package.dirPath = [@"/project/pack_old" pathByAppendingPackageSuffix];

    ProjectSettings *projectSettings = [[ProjectSettings alloc] init];
    projectSettings.projectPath = @"/project";
    _packageController.projectSettings = projectSettings;
    [projectSettings addResourcePath:package.dirPath error:nil];

    id resourceManagerMock = [OCMockObject niceMockForClass:[ResourceManager class]];
    _packageController.resourceManager = resourceManagerMock;

    NSString *destPath = [@"/project/foo" pathByAppendingPackageSuffix];
    [[[_fileManagerMock expect] andReturnValue:@(YES)] moveItemAtPath:package.dirPath toPath:destPath error:[OCMArg anyObjectRef]];
    [[[_fileManagerMock expect] andReturnValue:@(NO)] fileExistsAtPath:OCMOCK_ANY];

    NSError *error;
    XCTAssertTrue([_packageController renamePackage:package toName:@"foo" error:&error]);
    XCTAssertNil(error);

    [_fileManagerMock verify];
}

- (void)testRenamePackageWithSameName
{
    RMPackage *package = [[RMPackage alloc] init];
    package.dirPath = [@"/project/pack_old" pathByAppendingPackageSuffix];

    id resourceManagerMock = [OCMockObject niceMockForClass:[ResourceManager class]];
    _packageController.resourceManager = resourceManagerMock;

    XCTAssertTrue([_packageController renamePackage:package toName:@"pack_old" error:nil]);
}

@end
