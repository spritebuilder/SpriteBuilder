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
    [self createFolders:@[@"SpriteBuilder Resources"]];
    [self createEmptyFiles:@[
            @"SpriteBuilder Resources/asset.png",
            @"SpriteBuilder Resources/scene.ccb"]];

    [self setProjectsResourcePaths:@[@"SpriteBuilder Resources"]];

    NSError *error;
    XCTAssertTrue([_packageMigrator migrate:&error], @"Migration failed, error: %@", error);
    XCTAssertNil(error);

    [self assertFileExists:@"packages"];
    [self assertFileDoesNotExists:@"SpriteBuilder Resources"];
    [self assertFileExists:[@"packages/SpriteBuilder Resources" stringByAppendingPackageSuffix]];
    [self assertFileExists:[[@"packages/SpriteBuilder Resources" stringByAppendingPackageSuffix] stringByAppendingPathComponent:@"asset.png"]];
    [self assertResourcePathsInProject:@[[_projectSettings fullPathForPackageName:@"SpriteBuilder Resources"]]];
    [self assertResourcePathsNotInProject:@[[self fullPathForFile:@"SpriteBuilder Resources"]]];
}

- (void)testMigrationWithExistingPackagesFolderAsResourcePath
{
    [self createFolders:@[@"packages"]];

    [self createEmptyFiles:@[
            @"packages/asset.png",
            @"packages/scene.ccb"]];

    [self setProjectsResourcePaths:@[@"packages"]];

    NSError *error;
    XCTAssertTrue([_packageMigrator migrate:&error], @"Migration failed, error: %@", error);
    XCTAssertNil(error);

    [self assertFileExists:@"packages"];
    [self assertFileExists:[@"packages/packages" stringByAppendingPackageSuffix]];
    [self assertFileExists:[[@"packages/packages" stringByAppendingPackageSuffix] stringByAppendingPathComponent:@"asset.png"]];

    [self assertResourcePathsInProject:@[[_projectSettings fullPathForPackageName:@"packages"]]];
    [self assertResourcePathsNotInProject:@[[self fullPathForFile:@"packages"]]];
}

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
