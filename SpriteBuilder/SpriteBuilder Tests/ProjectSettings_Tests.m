//
//  ProjectSettings_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 28.05.14.
//
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import "ProjectSettings.h"
#import "SBErrors.h"
#import "ProjectSettings+Packages.h"
#import "NSString+Packages.h"
#import "SBAssserts.h"
#import "MiscConstants.h"

@interface ProjectSettings_Tests : XCTestCase

@end


@implementation ProjectSettings_Tests
{
    ProjectSettings *_projectSettings;
}

- (void)setUp
{
    [super setUp];

    _projectSettings = [[ProjectSettings alloc] init];
    _projectSettings.projectPath = @"/project/abc.ccbproj";
}

- (void)testStandardInitialization
{
    XCTAssertEqual((int)_projectSettings.resourcePaths.count, 1);
    id firstResourcePath = _projectSettings.resourcePaths[0];
    XCTAssertEqualObjects([firstResourcePath objectForKey:@"path"], @"Resources");
}

- (void)testAddResourcePath
{
    NSError *error;
    XCTAssertTrue([_projectSettings addResourcePath:@"/project/resourcepath1" error:&error]);
    XCTAssertNil(error);
    // Default init will add a default value to resourcePaths, see testStandardInitialization
    XCTAssertEqual((int)_projectSettings.resourcePaths.count, 2);
}

- (void)testAddResourcePathTwice
{
    NSString *resourcePath = @"/project/resourcepath1";

    NSError *error;
    XCTAssertTrue([_projectSettings addResourcePath:resourcePath error:&error]);
    XCTAssertNil(error);

    NSError *error2;
    XCTAssertFalse([_projectSettings addResourcePath:resourcePath error:&error2]);
    XCTAssertNotNil(error2);
    XCTAssertEqual(error2.code, SBDuplicateResourcePathError);

    XCTAssertEqual((int)_projectSettings.resourcePaths.count, 2);
}

- (void)testIsResourcePathAlreadyInProject
{
    NSString *resourcePath = @"/project/resourcepath1";

    [_projectSettings addResourcePath:resourcePath error:nil];

    XCTAssertTrue([_projectSettings isResourcePathInProject:resourcePath]);

    XCTAssertFalse([_projectSettings isResourcePathInProject:@"/foo/notinproject"]);
}

- (void)testRemoveResourcePath
{
    _projectSettings.projectPath = @"/project/ccbuttonwooga.ccbproj";
    [_projectSettings.resourcePaths addObject:@{@"path" : @"test"}];

    NSError *error;
    XCTAssertTrue([_projectSettings removeResourcePath:@"/project/test" error:&error]);
    // Default init will add a default value to resourcePaths, see testStandardInitialization
    XCTAssertEqual((int)_projectSettings.resourcePaths.count, 1);
    XCTAssertNil(error);
}

- (void)testRemoveNonExistingResourcePath
{
    _projectSettings.projectPath = @"/project/ccbuttonwooga.ccbproj";

    NSError *error;
    XCTAssertFalse([_projectSettings removeResourcePath:@"/project/test" error:&error]);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, SBResourcePathNotInProjectError);
}

- (void)testMoveResourcePath
{
    _projectSettings.projectPath = @"/project/ccbuttonwooga.ccbproj";

    NSString *pathOld = @"/somewhere/path_old";
    [_projectSettings addResourcePath:pathOld error:nil];

    NSString *pathNew = @"/somewhere/path_new";
    NSError *error;
    XCTAssertTrue([_projectSettings moveResourcePathFrom:pathOld toPath:pathNew error:&error]);
    XCTAssertNil(error);

    XCTAssertFalse([_projectSettings isResourcePathInProject:pathOld]);
    XCTAssertTrue([_projectSettings isResourcePathInProject:pathNew]);
}

- (void)testMoveResourcePathFailingBecauseThereIsAlreadyOneWithTheSameName
{
    NSString *path1 = @"/somewhere/path1";
    [_projectSettings addResourcePath:path1 error:nil];
    NSString *path2 = @"/somewhere/path2";
    [_projectSettings addResourcePath:path2 error:nil];

    NSError *error;
    XCTAssertFalse([_projectSettings moveResourcePathFrom:path1 toPath:path2 error:&error]);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, SBDuplicateResourcePathError);
}

- (void)testFullPathForPackageName
{
    NSString *packageName = @"foo";
    NSString *fullPackagesPath = [_projectSettings.projectPathDir stringByAppendingPathComponent:PACKAGES_FOLDER_NAME];

    NSString *fullPathForPackageName = [_projectSettings fullPathForPackageName:packageName];
    NSString *supposedFullPath = [fullPackagesPath stringByAppendingPathComponent:[packageName stringByAppendingPackageSuffix]];

    SBAssertStringsEqual(fullPathForPackageName,supposedFullPath);
}

- (void)testIsPathWithinPackagesFolder
{
    NSString *pathWithinPackagesFolder = [_projectSettings.packagesFolderPath stringByAppendingPathComponent:@"foo"];

    XCTAssertTrue([_projectSettings isPathInPackagesFolder:pathWithinPackagesFolder]);
}

- (void)testPackagesFolderPath
{
    NSString *fullPackagesPath = [_projectSettings.projectPathDir stringByAppendingPathComponent:PACKAGES_FOLDER_NAME];

    SBAssertStringsEqual(fullPackagesPath, _projectSettings.packagesFolderPath);
}

@end
