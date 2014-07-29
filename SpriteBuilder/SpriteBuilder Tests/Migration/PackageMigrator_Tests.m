//
//  PackageMigrator_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 24.06.14.
//
//

#import <XCTest/XCTest.h>
#import "PackageMigrator.h"
#import "ProjectSettings.h"
#import "FileSystemTestCase.h"
#import "NSString+Packages.h"
#import "ProjectSettings+Packages.h"


@interface PackageMigrator_Tests : FileSystemTestCase

@property (nonatomic, strong) ProjectSettings *projectSettings;
@property (nonatomic, strong) PackageMigrator *packageMigrator;

@end


@implementation PackageMigrator_Tests

- (void)setUp
{
    [super setUp];

    [self createProjectSettingsFileWithName:@"migrationtest"];

    self.projectSettings = [self loadProjectSettingsWithProjectName:@"migrationtest"];

    self.packageMigrator = [[PackageMigrator alloc] initWithProjectSettings:_projectSettings];
}


#pragma mark - setup

- (ProjectSettings *)loadProjectSettingsWithProjectName:(NSString *)projectName
{
    NSString *projectFileName = [NSString stringWithFormat:@"%@.ccbproj", projectName];
    NSString *projectSettingsPath = [self fullPathForFile:projectFileName];

    NSMutableDictionary *projectDict = [NSMutableDictionary dictionaryWithContentsOfFile:projectSettingsPath];
    ProjectSettings *projectSettings = [[ProjectSettings alloc] initWithSerialization:projectDict];
    projectSettings.projectPath = projectSettingsPath;

    [self assertFileExists:projectFileName];

    return projectSettings;
}

- (void)setProjectsResourcePaths:(NSArray *)resourcePaths
{
    for (NSString *resourcePath in resourcePaths)
    {
        [_projectSettings addResourcePath:[self fullPathForFile:resourcePath] error:nil];
    }
}


#pragma mark - tests

- (void)testMigrationStandardCaseNoPackageFolderNoPackages
{
    [self createEmptyFiles:@[
            @"SpriteBuilder Resources/asset.png",
            @"SpriteBuilder Resources/scene.ccb"]];

    [self setProjectsResourcePaths:@[@"SpriteBuilder Resources"]];

    NSError *error;
    XCTAssertTrue([_packageMigrator migrate:&error], @"Migration failed, error: %@", error);
    XCTAssertNil(error);

    [self assertFileExists:@"packages"];
    [self assertFileDoesNotExist:@"SpriteBuilder Resources"];
    [self assertFileExists:[@"packages/SpriteBuilder Resources" stringByAppendingPackageSuffix]];
    [self assertFileExists:[[@"packages/SpriteBuilder Resources" stringByAppendingPackageSuffix] stringByAppendingPathComponent:@"asset.png"]];
    [self assertResourcePathsInProject:@[[_projectSettings fullPathForPackageName:@"SpriteBuilder Resources"]]];
    [self assertResourcePathsNotInProject:@[[self fullPathForFile:@"SpriteBuilder Resources"]]];
}

- (void)testMigrationWithExistingPackagesFolderAsResourcePath
{
    [self createEmptyFiles:@[
            @"Packages/asset.png",
            @"Packages/scene.ccb"]];

    [self setProjectsResourcePaths:@[@"Packages"]];

    NSError *error;
    XCTAssertTrue([_packageMigrator migrate:&error], @"Migration failed, error: %@", error);
    XCTAssertNil(error);

    [self assertFileExists:@"Packages"];
    [self assertFileExists:[@"Packages/Packages" stringByAppendingPackageSuffix]];
    [self assertFileExists:[[@"Packages/Packages" stringByAppendingPackageSuffix] stringByAppendingPathComponent:@"asset.png"]];

    [self assertResourcePathsInProject:@[[_projectSettings fullPathForPackageName:@"Packages"]]];
    [self assertResourcePathsNotInProject:@[[self fullPathForFile:@"Packages"]]];
}


- (void)testWithExistingPackagesFolderAndANotInProjectPackageFolderInside
{
    [self createEmptyFiles:@[@"sprites/asset.png"]];

    [self createEmptyFiles:@[@"Packages/sprites.sbpack/smiley.png"]];

    [self setProjectsResourcePaths:@[@"sprites"]];

    NSError *error;
    XCTAssertTrue([_packageMigrator migrate:&error], @"Migration failed, error: %@", error);
    XCTAssertNil(error);

    [self assertFileExists:[@"Packages/sprites" stringByAppendingPackageSuffix]];
    [self assertFileExists:[[@"Packages/sprites" stringByAppendingPackageSuffix] stringByAppendingPathComponent:@"asset.png"]];

    [self assertFileDoesNotExist:[[@"Packages/sprites" stringByAppendingPackageSuffix] stringByAppendingPathComponent:@"smiley.png"]];

    // This is a bit brittle, but should be easily fixed if renaming rules change
    [self assertFileExists:[[@"Packages/sprites" stringByAppendingPackageSuffix] stringByAppendingString:@".renamed"]];
    [self assertResourcePathsInProject:@[[_projectSettings fullPathForPackageName:@"sprites"]]];
}

- (void)testImportingAResourcePathWithPackageSuffixButOutsidePackagesFolder
{
    [self createFolders:@[[@"sprites" stringByAppendingPackageSuffix]]];
    [self setProjectsResourcePaths:@[[@"sprites" stringByAppendingPackageSuffix]]];

    NSError *error;
    XCTAssertTrue([_packageMigrator migrate:&error], @"Migration failed, error: %@", error);
    XCTAssertNil(error);

    [self assertFileExists:[@"packages/sprites" stringByAppendingPackageSuffix]];
    [self assertFileDoesNotExist:[@"sprites" stringByAppendingPackageSuffix]];
    [self assertFileDoesNotExist:[[@"packages/sprites" stringByAppendingPackageSuffix] stringByAppendingPackageSuffix]];

    [self assertResourcePathsInProject:@[[_projectSettings fullPathForPackageName:@"sprites"]]];
}

- (void)testRollback
{
    [self createEmptyFiles:@[
            @"SpriteBuilder Resources/asset.png",
            @"SpriteBuilder Resources/scene.ccb"]];

    [self setProjectsResourcePaths:@[@"SpriteBuilder Resources"]];

    NSError *error;
    XCTAssertTrue([_packageMigrator migrate:&error], @"Migration failed, error: %@", error);
    XCTAssertNil(error);

    [_packageMigrator rollback];

    [self assertFileExists:@"SpriteBuilder Resources/asset.png"];
    [self assertFileExists:@"SpriteBuilder Resources/scene.ccb"];
    [self assertFileDoesNotExist:@"packages"];
    [self assertResourcePathsInProject:@[[self fullPathForFile:@"SpriteBuilder Resources"]]];
    XCTAssertTrue(_projectSettings.resourcePaths.count == 1, @"There should be only 1 resourcepath but %lu found: %@", _projectSettings.resourcePaths.count, _projectSettings.resourcePaths);
}


#pragma mark - assertion helper

- (void)assertResourcePathsInProject:(NSArray *)resourcePaths
{
    for (NSString *resourcePath in resourcePaths)
    {
        XCTAssertTrue([_projectSettings isResourcePathInProject:resourcePath], @"Resource path \"%@\"is not in project settings. Found in settings: %@", resourcePath, _projectSettings.resourcePaths);
    }
}

- (void)assertResourcePathsNotInProject:(NSArray *)resourcePaths
{
    for (NSString *resourcePath in resourcePaths)
    {
        XCTAssertFalse([_projectSettings isResourcePathInProject:resourcePath], @"Resource path \"%@\"is in project settings.");
    }
}

@end
