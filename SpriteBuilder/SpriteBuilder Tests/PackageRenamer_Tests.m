//
//  PackageRenamer_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 16.06.14.
//
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import "ProjectSettings.h"
#import "NSString+Packages.h"
#import "SBErrors.h"
#import "RMPackage.h"
#import "ResourceManager.h"
#import "PackageRenamer.h"

@interface PackageRenamer_Tests : XCTestCase

@end

@implementation PackageRenamer_Tests
{
    PackageRenamer *_packageRenamer;
    ProjectSettings *_projectSettings;
    id _fileManagerMock;
}

- (void)setUp
{
    [super setUp];

    _packageRenamer = [[PackageRenamer alloc] init];

    _projectSettings = [[ProjectSettings alloc] init];
    _projectSettings.projectPath = @"/packagestests.ccbproj";
    _packageRenamer.projectSettings = _projectSettings;

    _fileManagerMock = [OCMockObject niceMockForClass:[NSFileManager class]];
    _packageRenamer.fileManager = _fileManagerMock;
}

- (void)testCanRenamePackageWithExistingFullPathInProject
{
    RMPackage *package = [[RMPackage alloc] init];
    package.dirPath = [@"/project/pack_old" stringByAppendingPackageSuffix];

    [_projectSettings addResourcePath:[@"/project/pack_new" stringByAppendingPackageSuffix] error:nil];

    NSError *error;
    XCTAssertFalse([_packageRenamer canRenamePackage:package toName:@"pack_new" error:&error]);
    XCTAssertEqual(error.code, SBDuplicateResourcePathError);
}

- (void)testCanRenamePackageWithExistingFullPathInFileSystemButNotInProject
{
    RMPackage *package = [[RMPackage alloc] init];
    package.dirPath = [@"/project/pack_old" stringByAppendingPackageSuffix];

    [[[_fileManagerMock expect] andReturnValue:@(YES)] fileExistsAtPath:[@"/project/pack_new" stringByAppendingPackageSuffix]];

    NSError *error;
    XCTAssertFalse([_packageRenamer canRenamePackage:package toName:@"pack_new" error:&error]);
    XCTAssertEqual(error.code, SBResourcePathExistsButNotInProjectError);

    [_fileManagerMock verify];
}

- (void)testCanRenamePackage
{
    RMPackage *package = [[RMPackage alloc] init];
    package.dirPath = [@"/project/pack_old" stringByAppendingPackageSuffix];

    [[[_fileManagerMock expect] andReturnValue:@(NO)] fileExistsAtPath:OCMOCK_ANY];

    XCTAssertTrue([_packageRenamer canRenamePackage:package toName:@"pack_new" error:nil]);

    [_fileManagerMock verify];
}

- (void)testCanRenamePackageWithNoChange
{
    RMPackage *package = [[RMPackage alloc] init];
    package.dirPath = [@"/project/pack_old" stringByAppendingPackageSuffix];

    XCTAssertTrue([_packageRenamer canRenamePackage:package toName:package.dirPath error:nil]);
}

- (void)testRenamePackage
{
    RMPackage *package = [[RMPackage alloc] init];
    package.dirPath = [@"/project/pack_old" stringByAppendingPackageSuffix];

    [_projectSettings addResourcePath:package.dirPath error:nil];

    id resourceManagerMock = [OCMockObject niceMockForClass:[ResourceManager class]];
    _packageRenamer.resourceManager = resourceManagerMock;

    NSString *destPath = [@"/project/foo" stringByAppendingPackageSuffix];
    [[[_fileManagerMock expect] andReturnValue:@(YES)] moveItemAtPath:package.dirPath toPath:destPath error:[OCMArg anyObjectRef]];
    [[[_fileManagerMock expect] andReturnValue:@(NO)] fileExistsAtPath:OCMOCK_ANY];

    NSError *error;
    XCTAssertTrue([_packageRenamer renamePackage:package toName:@"foo" error:&error]);
    XCTAssertNil(error);

    [_fileManagerMock verify];
}

- (void)testRenamePackageWithSameName
{
    RMPackage *package = [[RMPackage alloc] init];
    package.dirPath = [@"/project/pack_old" stringByAppendingPackageSuffix];

    id resourceManagerMock = [OCMockObject niceMockForClass:[ResourceManager class]];
    _packageRenamer.resourceManager = resourceManagerMock;

    XCTAssertTrue([_packageRenamer renamePackage:package toName:@"pack_old" error:nil]);
}


@end
