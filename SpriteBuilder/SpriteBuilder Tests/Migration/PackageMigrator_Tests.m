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

@end

@implementation PackageMigrator_Tests

#pragma mark - setup

- (ProjectSettings *)createProjectSettingsWithResourcePaths:(NSArray *)resourcePaths
{
    NSString *projectSettingsPath = [self fullPathForFile:@"migrationtest.ccbproj"];

    NSMutableDictionary *projectDict = [NSMutableDictionary dictionaryWithContentsOfFile:projectSettingsPath];
    ProjectSettings *projectSettings = [[ProjectSettings alloc] initWithSerialization:projectDict];
    projectSettings.projectPath = projectSettingsPath;

    for (NSString *resourcePath in resourcePaths)
    {
        [projectSettings addResourcePath:[self fullPathForFile:resourcePath] error:nil];
    }

    return projectSettings;
}


#pragma mark - tests

- (void)testMigrationStandardCaseNoPackageFolderNoPackages
{
    [self createFolders:@[@"SpriteBuilder Resources"]];

    [self createProjectSettingsFileWithName:@"migrationtest"];
    [self assertFileExists:@"migrationtest.ccbproj"];

    [self createEmptyFiles:@[
            @"SpriteBuilder Resources/asset.png",
            @"SpriteBuilder Resources/scene.ccb"]];

    ProjectSettings *projectSettings = [self createProjectSettingsWithResourcePaths:@[@"SpriteBuilder Resources"]];

    PackageMigrator *packageMigrator = [[PackageMigrator alloc] initWithProjectSettings:projectSettings];

    NSError *error;
    XCTAssertTrue([packageMigrator migrate:&error], @"Migration failed, error: %@", error);
    XCTAssertNil(error);

    [self assertFileExists:@"packages"];
    [self assertFileDoesNotExists:@"SpriteBuilder Resources"];
    [self assertFileExists:[@"packages/SpriteBuilder Resources" stringByAppendingPackageSuffix]];
    [self assertFileExists:[[@"packages/SpriteBuilder Resources" stringByAppendingPackageSuffix] stringByAppendingPathComponent:@"asset.png"]];
    [self assertResourcePaths:@[[projectSettings fullPathForPackageName:@"SpriteBuilder Resources"]]
            inProjectSettings:projectSettings];
    [self assertResourcePaths:@[[self fullPathForFile:@"SpriteBuilder Resources"]]
            notInProjectSettings:projectSettings];
}

- (void)testMigrationWithExistingPackagesFolderAsResourcePath
{
    [self createFolders:@[@"packages"]];

    [self createEmptyFiles:@[
            @"packages/asset.png",
            @"packages/scene.ccb"]];

    [self createProjectSettingsFileWithName:@"migrationtest"];
    [self assertFileExists:@"migrationtest.ccbproj"];

    ProjectSettings *projectSettings = [self createProjectSettingsWithResourcePaths:@[@"packages"]];

    PackageMigrator *packageMigrator = [[PackageMigrator alloc] initWithProjectSettings:projectSettings];

    NSError *error;
    XCTAssertTrue([packageMigrator migrate:&error], @"Migration failed, error: %@", error);
    XCTAssertNil(error);

    [self assertFileExists:@"packages"];
    [self assertFileExists:[@"packages/packages" stringByAppendingPackageSuffix]];
    [self assertFileExists:[[@"packages/packages" stringByAppendingPackageSuffix] stringByAppendingPathComponent:@"asset.png"]];

    [self assertResourcePaths:@[[projectSettings fullPathForPackageName:@"packages"]] inProjectSettings:projectSettings];
    [self assertResourcePaths:@[[self fullPathForFile:@"packages"]] notInProjectSettings:projectSettings];
}


#pragma mark - assertion helper

- (void)assertResourcePaths:(NSArray *)resourcePaths inProjectSettings:(ProjectSettings *)projectSettings
{
    for (NSString *resourcePath in resourcePaths)
    {
        XCTAssertTrue([projectSettings isResourcePathInProject:resourcePath], @"Resource path \"%@\"is not in project settings. Found in settings: %@", resourcePath, projectSettings.resourcePaths);
    }
}

- (void)assertResourcePaths:(NSArray *)resourcePaths notInProjectSettings:(ProjectSettings *)projectSettings
{
    for (NSString *resourcePath in resourcePaths)
    {
        XCTAssertFalse([projectSettings isResourcePathInProject:resourcePath], @"Resource path \"%@\"is in project settings.");
    }
}

@end
