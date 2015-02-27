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
#import "Errors.h"
#import "ProjectSettings.h"
#import "PackageImporter.h"
#import "MiscConstants.h"
#import "ProjectSettings+Packages.h"
#import "FileSystemTestCase.h"

@interface PackageImporter_Tests : FileSystemTestCase

@property (nonatomic, strong) id fileManagerMock;
@property (nonatomic, strong) PackageImporter *packageImporter;
@property (nonatomic, strong) ProjectSettings *projectSettings;

@end


@implementation PackageImporter_Tests

- (void)setUp
{
    [super setUp];

    self.packageImporter = [[PackageImporter alloc] init];

    self.projectSettings = [self createProjectSettingsFileWithName:@"foo.spritebuilder/foo"];
    _packageImporter.projectSettings = _projectSettings;

    self.fileManagerMock = [OCMockObject niceMockForClass:[NSFileManager class]];
    _packageImporter.fileManager = _fileManagerMock;
}

- (void)testImportPackageWithName
{
    [self createFolders:@[@"foo.spritebuilder/Packages/foo.sbpack"]];

    [[[_fileManagerMock expect] andReturnValue:@(YES)] copyItemAtPath:OCMOCK_ANY toPath:OCMOCK_ANY error:[OCMArg anyObjectRef]];

    NSError *error;
    XCTAssertTrue([_packageImporter importPackageWithName:@"foo" error:&error]);
    XCTAssertNil(error);
}

// One package is addable
// The other one already is in the project
- (void)testImportPackagesWithTwoPackages
{
    [self createFolders:@[@"foo.spritebuilder/Packages/notYetInProject.sbpack"]];

    id observerMock = [ObserverTestHelper observerMockForNotification:RESOURCE_PATHS_CHANGED];

    NSString *packagePathNotInProject = [@"/notYetInProject" stringByAppendingPackageSuffix];
    NSString *packagePathInProject = [_projectSettings fullPathForPackageName:@"alreadyInProject"];
    NSArray *packagePaths = @[packagePathNotInProject, packagePathInProject];

    [[[_fileManagerMock expect] andReturnValue:@(YES)] copyItemAtPath:OCMOCK_ANY toPath:OCMOCK_ANY error:[OCMArg anyObjectRef]];

    [_projectSettings addPackageWithFullPath:packagePathInProject error:nil];

    NSError *error;
    XCTAssertFalse([_packageImporter importPackagesWithPaths:packagePaths error:&error]);
    XCTAssertNotNil(error);

    NSArray *errors = error.userInfo[@"errors"];
    XCTAssertEqual((int)errors.count, 1);
    XCTAssertEqual(error.code, SBImportingPackagesError);
    NSError *underlyingError = errors[0];
    XCTAssertEqual(underlyingError.code, SBPackageAlreayInProject);

    [ObserverTestHelper verifyAndRemoveObserverMock:observerMock];
}

- (void)testImportPackageSuccessfully
{
    [self createFolders:@[@"foo.spritebuilder/Packages/foo.sbpack"]];

    id observerMock = [ObserverTestHelper observerMockForNotification:RESOURCE_PATHS_CHANGED];

    NSString *packagePath = [@"/somewhere/foo" stringByAppendingPackageSuffix];
    NSString *packagesName = [[packagePath lastPathComponent] stringByDeletingPathExtension];
    NSString *importedPackagePath = [_projectSettings fullPathForPackageName:packagesName];

    [[[_fileManagerMock expect] andReturnValue:@(YES)] copyItemAtPath:packagePath toPath:importedPackagePath error:[OCMArg anyObjectRef]];

    NSError *error;
    XCTAssertTrue([_packageImporter importPackagesWithPaths:@[packagePath] error:&error]);
    XCTAssertNil(error);
    [ObserverTestHelper verifyAndRemoveObserverMock:observerMock];

    XCTAssertTrue([_projectSettings isPackageWithFullPathInProject:importedPackagePath], @"imported package's path should be: %@, but it was not found in project settings. Paths in settings: %@", importedPackagePath, _projectSettings.packages);

    [_fileManagerMock verify];
}

- (void)testImportOfExistingPackageInFileSystem
{
    NSString *packagePath = [@"/somewhere/foo" stringByAppendingPackageSuffix];
    NSString *packagesName = [[packagePath lastPathComponent] stringByDeletingPathExtension];
    NSString *importedPackagePath = [_projectSettings fullPathForPackageName:packagesName];

    NSError *fileSystemError = [NSError errorWithDomain:@"some domain" code:123 userInfo:nil];
    [[[_fileManagerMock expect] andReturnValue:@(NO)] copyItemAtPath:packagePath toPath:importedPackagePath error:((NSError __autoreleasing **)[OCMArg setTo:fileSystemError])];

    NSError *error;
    XCTAssertFalse([_packageImporter importPackagesWithPaths:@[packagePath] error:&error]);
    XCTAssertNotNil(error);

    XCTAssertFalse([_projectSettings isPackageWithFullPathInProject:importedPackagePath], @"imported package's path should be: %@, but it was not found in project settings. Paths in settings: %@", importedPackagePath, _projectSettings.packages);

    [_fileManagerMock verify];
}

- (void)testReImportPackageInPackageFolderButNotInProject
{
    [self createFolders:@[@"foo.spritebuilder/Packages/foo.sbpack"]];

    _fileManagerMock = [OCMockObject mockForClass:[NSFileManager class]];

    NSString *toImportPackagePath = [_projectSettings fullPathForPackageName:@"foo"];

    NSError *error;
    XCTAssertTrue([_packageImporter importPackagesWithPaths:@[toImportPackagePath] error:&error]);
    XCTAssertNil(error);

    XCTAssertTrue([_projectSettings isPackageWithFullPathInProject:toImportPackagePath], @"imported package's path should be: %@, but it was not found in project settings. Paths in settings: %@", toImportPackagePath, _projectSettings.packages);

    [_fileManagerMock verify];
}

- (void)testImportPackageWithInvalidPaths
{
    NSError *error1;
    XCTAssertFalse([_packageImporter importPackagesWithPaths:nil error:&error1]);
    XCTAssertNotNil(error1);
    XCTAssertEqual(error1.code, SBNoPackagePathsToImport);

    NSError *error2;
    XCTAssertFalse([_packageImporter importPackagesWithPaths:@[] error:&error2]);
    XCTAssertNotNil(error2);
    XCTAssertEqual(error2.code, SBNoPackagePathsToImport);

    NSError *error3;
    XCTAssertFalse([_packageImporter importPackagesWithPaths:@[@"/foo/package"] error:&error3]);
    XCTAssertNotNil(error3);
    XCTAssertEqual(error3.code, SBPathWithoutPackageSuffix);
}

- (void)testImportPackageRealCase
{
    [self createFolders:@[@"foo.spritebuilder/Packages"]];
    [self createEmptyFilesRelativeToDirectory:@"toimport/baa.sbpack" files:@[
        @"images/resources-auto/sky.png",
        @"sounds/rain.wav"
    ]];

    _packageImporter.fileManager = [NSFileManager defaultManager];

    NSError *error;
    XCTAssertTrue([_packageImporter importPackagesWithPaths:@[[self fullPathForFile:@"toimport/baa.sbpack"]] error:&error]);
    XCTAssertNil(error);

    [self assertFilesExistRelativeToDirectory:@"foo.spritebuilder/Packages/baa.sbpack" filesPaths:@[
        @"images/resources-auto/sky.png",
        @"sounds/rain.wav",
        @"Package.plist"
    ]];

    XCTAssertTrue([_projectSettings isPackageWithFullPathInProject:[self fullPathForFile:@"foo.spritebuilder/Packages/baa.sbpack"]]);
}

@end
