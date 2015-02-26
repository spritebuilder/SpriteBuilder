//
//  PackageMigrator_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 24.06.14.
//
//

#import <XCTest/XCTest.h>
#import "ResourcePathToPackageMigrator.h"
#import "ProjectSettings.h"
#import "FileSystemTestCase.h"
#import "NSString+Packages.h"
#import "ProjectSettings+Packages.h"
#import "MiscConstants.h"


@interface ResourcePathToPackageMigrator_Tests : FileSystemTestCase

@property (nonatomic, copy) NSString *projectSettingsFilePath;

@end


@implementation ResourcePathToPackageMigrator_Tests

- (void)setUp
{
    [super setUp];

    ProjectSettings *projectSettings = [self createProjectSettingsFileWithName:@"migrationtest"];
    self.projectSettingsFilePath = projectSettings.projectPath; 
}


#pragma mark - setup

- (void)setProjectsResourcePaths:(NSArray *)resourcePaths
{
    ProjectSettings *projectSettings = [[ProjectSettings alloc] initWithFilepath:_projectSettingsFilePath];

    for (NSString *resourcePath in resourcePaths)
    {
        [projectSettings addResourcePath:[self fullPathForFile:resourcePath] error:nil];
    }

    [projectSettings store];
}


#pragma mark - tests

- (void)testMigrationStandardCaseNoPackageFolderNoPackages
{
    [self createEmptyFiles:@[
            @"SpriteBuilder Resources/asset.png",
            @"SpriteBuilder Resources/song.wav"]];

    [self setProjectsResourcePaths:@[@"SpriteBuilder Resources"]];

    ResourcePathToPackageMigrator *packageMigrator = [[ResourcePathToPackageMigrator alloc]
                                                                                     initWithProjectFilePath:_projectSettingsFilePath];

    XCTAssertTrue([packageMigrator isMigrationRequired]);

    NSError *error;
    XCTAssertTrue([packageMigrator migrateWithError:&error], @"Migration failed, error: %@", error);
    XCTAssertNil(error);

    ProjectSettings *projectSettings = [[ProjectSettings alloc] initWithFilepath:_projectSettingsFilePath];

    [self assertFileExists:@"packages"];
    [self assertFileDoesNotExist:@"SpriteBuilder Resources"];
    [self assertFileExists:[@"packages/SpriteBuilder Resources" stringByAppendingPackageSuffix]];
    [self assertFileExists:[[@"packages/SpriteBuilder Resources" stringByAppendingPackageSuffix] stringByAppendingPathComponent:@"asset.png"]];
    [self assertResourcePathsInProject:@[[projectSettings fullPathForPackageName:@"SpriteBuilder Resources"]] inProjectSettings:projectSettings];
    [self assertResourcePathsNotInProject:@[[self fullPathForFile:@"SpriteBuilder Resources"]] inProjectSettings:nil];
}

- (void)testMigrationWithExistingPackagesFolderAsResourcePath
{
    [self createEmptyFiles:@[
            @"Packages/asset.png",
            @"Packages/song.wav"]];

    [self setProjectsResourcePaths:@[@"Packages"]];

    ResourcePathToPackageMigrator *packageMigrator = [[ResourcePathToPackageMigrator alloc]
                                                                                     initWithProjectFilePath:_projectSettingsFilePath];

    XCTAssertTrue([packageMigrator isMigrationRequired]);

    XCTAssertTrue([packageMigrator isMigrationRequired]);

    NSError *error;
    XCTAssertTrue([packageMigrator migrateWithError:&error], @"Migration failed, error: %@", error);
    XCTAssertNil(error);

    ProjectSettings *projectSettings = [[ProjectSettings alloc] initWithFilepath:_projectSettingsFilePath];

    [self assertFileExists:@"Packages"];
    [self assertFileExists:[@"Packages/Packages" stringByAppendingPackageSuffix]];
    [self assertFileExists:[[@"Packages/Packages" stringByAppendingPackageSuffix] stringByAppendingPathComponent:@"asset.png"]];

    [self assertResourcePathsInProject:@[[projectSettings fullPathForPackageName:@"Packages"]] inProjectSettings:projectSettings];
    [self assertResourcePathsNotInProject:@[[self fullPathForFile:@"Packages"]] inProjectSettings:nil];
}

- (void)testWithExistingPackagesFolderAndANotInProjectPackageFolderInside
{
    [self createEmptyFiles:@[@"sprites/asset.png"]];

    [self createEmptyFiles:@[@"Packages/sprites.sbpack/smiley.png"]];

    [self setProjectsResourcePaths:@[@"sprites"]];

    ResourcePathToPackageMigrator *packageMigrator = [[ResourcePathToPackageMigrator alloc]
                                                                                     initWithProjectFilePath:_projectSettingsFilePath];

    XCTAssertTrue([packageMigrator isMigrationRequired]);

    NSError *error;
    XCTAssertTrue([packageMigrator migrateWithError:&error], @"Migration failed, error: %@", error);
    XCTAssertNil(error);

    ProjectSettings *projectSettings = [[ProjectSettings alloc] initWithFilepath:_projectSettingsFilePath];

    [self assertFileExists:[@"Packages/sprites" stringByAppendingPackageSuffix]];
    [self assertFileExists:[[@"Packages/sprites" stringByAppendingPackageSuffix] stringByAppendingPathComponent:@"asset.png"]];

    [self assertFileDoesNotExist:[[@"Packages/sprites" stringByAppendingPackageSuffix] stringByAppendingPathComponent:@"smiley.png"]];

    // This is a bit brittle, but should be easily fixed if renaming rules change
    [self assertFileExists:[[@"Packages/sprites" stringByAppendingPackageSuffix] stringByAppendingString:@".renamed"]];
    [self assertResourcePathsInProject:@[[projectSettings fullPathForPackageName:@"sprites"]] inProjectSettings:projectSettings];
}

- (void)testImportingAResourcePathWithPackageSuffixButOutsidePackagesFolder
{
    [self createFolders:@[[@"sprites" stringByAppendingPackageSuffix]]];
    [self setProjectsResourcePaths:@[[@"sprites" stringByAppendingPackageSuffix]]];

    ResourcePathToPackageMigrator *packageMigrator = [[ResourcePathToPackageMigrator alloc]
                                                                                     initWithProjectFilePath:_projectSettingsFilePath];

    XCTAssertTrue([packageMigrator isMigrationRequired]);

    NSError *error;
    XCTAssertTrue([packageMigrator migrateWithError:&error], @"Migration failed, error: %@", error);
    XCTAssertNil(error);

    ProjectSettings *projectSettings = [[ProjectSettings alloc] initWithFilepath:_projectSettingsFilePath];

    [self assertFileExists:[@"packages/sprites" stringByAppendingPackageSuffix]];
    [self assertFileDoesNotExist:[@"sprites" stringByAppendingPackageSuffix]];
    [self assertFileDoesNotExist:[[@"packages/sprites" stringByAppendingPackageSuffix] stringByAppendingPackageSuffix]];

    [self assertResourcePathsInProject:@[[projectSettings fullPathForPackageName:@"sprites"]] inProjectSettings:projectSettings];
}

- (void)testHtmlInfoText
{
    [self createFolders:@[@"foo.spritebuilder/Packages/package_a.sbpack"]];

    XCTAssertTrue([@{} writeToFile:[self fullPathForFile:[@"foo.spritebuilder/Packages/package_a.sbpack" stringByAppendingPathComponent:PACKAGE_PUBLISH_SETTINGS_FILE_NAME]] atomically:YES]);

    ResourcePathToPackageMigrator *packageMigrator = [[ResourcePathToPackageMigrator alloc]
                                                                                     initWithProjectFilePath:_projectSettingsFilePath];

    XCTAssertFalse([packageMigrator isMigrationRequired]);

    NSError *error;
    XCTAssertTrue([packageMigrator migrateWithError:&error]);
    XCTAssertNil(error);
}

- (void)testRollback
{
    [self createEmptyFiles:@[
            @"SpriteBuilder Resources/asset.png",
            @"SpriteBuilder Resources/song.wav"]];

    [self setProjectsResourcePaths:@[@"SpriteBuilder Resources"]];

    ResourcePathToPackageMigrator *packageMigrator = [[ResourcePathToPackageMigrator alloc]
                                                                                     initWithProjectFilePath:_projectSettingsFilePath];

    XCTAssertTrue([packageMigrator isMigrationRequired]);

    NSError *error;
    XCTAssertTrue([packageMigrator migrateWithError:&error], @"Migration failed, error: %@", error);
    XCTAssertNil(error);

    [packageMigrator rollback];

    ProjectSettings *projectSettings = [[ProjectSettings alloc] initWithFilepath:_projectSettingsFilePath];

    [self assertFileExists:@"SpriteBuilder Resources/asset.png"];
    [self assertFileExists:@"SpriteBuilder Resources/song.wav"];
    [self assertFileDoesNotExist:@"packages"];
    [self assertResourcePathsInProject:@[[self fullPathForFile:@"SpriteBuilder Resources"]] inProjectSettings:projectSettings];
    XCTAssertTrue(projectSettings.resourcePaths.count == 1, @"There should be only 1 resourcepath but %lu found: %@", projectSettings.resourcePaths.count, projectSettings.resourcePaths);
}

- (void)testMigrationNotRequired
{
    ResourcePathToPackageMigrator *packageMigrator = [[ResourcePathToPackageMigrator alloc]
                                                                                     initWithProjectFilePath:_projectSettingsFilePath];

    XCTAssertFalse([packageMigrator  isMigrationRequired]);
}


#pragma mark - assertion helper

- (void)assertResourcePathsInProject:(NSArray *)resourcePaths inProjectSettings:(ProjectSettings *)projectSettings
{
    for (NSString *resourcePath in resourcePaths)
    {
        XCTAssertTrue([projectSettings isResourcePathInProject:resourcePath], @"Resource path \"%@\"is not in project settings. Found in settings: %@", resourcePath, projectSettings.resourcePaths);
    }
}

- (void)assertResourcePathsNotInProject:(NSArray *)resourcePaths inProjectSettings:(ProjectSettings *)projectSettings
{
    for (NSString *resourcePath in resourcePaths)
    {
        XCTAssertFalse([projectSettings isResourcePathInProject:resourcePath], @"Resource path \"%@\"is in project settings.", resourcePath);
    }
}

@end
