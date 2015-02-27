//
//  MigrationIntegration_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 27.02.15.
//
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "CCBToSBRenameMigrator.h"
#import "MigratorData.h"
#import "PackageSettings.h"
#import "CCBDictionaryReader.h"
#import "ResourcePathToPackageMigrator.h"
#import "ProjectSettings.h"
#import "MigrationController.h"
#import "ProjectSettingsMigrator.h"
#import "AllDocumentsMigrator.h"
#import "AllPackageSettingsMigrator.h"
#import "FileSystemTestCase.h"
#import "FileSystemTestCase+ProjectFixtures.h"
#import "CCBDictionaryKeys.h"
#import "NSString+Packages.h"
#import "ProjectSettings+Packages.h"
#import "MigrationLogger.h"

@interface MigrationIntegration_Tests : FileSystemTestCase

@end

@implementation MigrationIntegration_Tests

- (void)testMigrationControllerWithFullProjectMigration
{
    // ProjectSettings should be renamed
    // ProjectSettings will be updated
    // Packages:
    //     package_a.sbpack/Package.plist will be updated
    //     package_a.sbpack/MainScene.ccb will be renamed and updated
    //     package_b.sbpack/Package.plist will be updated
    //     package_b.sbpack/scenes/credits.ccb will be renamed and updated

    NSString *pathPackage1 = @"foo.spritebuilder/Packages/package_1.sbpack";
    NSString *pathPackage2 = @"foo.spritebuilder/Packages/package_2.sbpack";

    NSString *pathPackage1PackageSettings = [pathPackage1 stringByAppendingPathComponent:@"Package.plist"];
    NSString *pathPackage2PackageSettings = [pathPackage2 stringByAppendingPathComponent:@"Package.plist"];


    // Setup: ProjectSettings

    ProjectSettings *projectSettings = [self createProjectSettingsFileWithName:@"foo.spritebuilder/foo.ccbproj"];

    XCTAssertTrue([projectSettings addPackageWithFullPath:[self fullPathForFile:pathPackage1] error:nil]);
    XCTAssertTrue([projectSettings addPackageWithFullPath:[self fullPathForFile:pathPackage2] error:nil]);

    [projectSettings store];

    // Setup: Packages

    [self createFolders:@[pathPackage1, pathPackage2]];

    [self createPackageSettingsVersion2WithPath:[pathPackage1 stringByAppendingPathComponent:@"Package.plist"]];
    // Package.plist is deliberately missing in package_2

    // Setup: Documents
    [self createCCBVersion4FileWithOldBlendFuncWithPath:[pathPackage1 stringByAppendingPathComponent:@"MainScene.ccb"]];
    [self createCCBVersion4FileWithOldBlendFuncWithPath:[pathPackage2 stringByAppendingPathComponent:@"scenes/credits.ccb"]];

    // Test
    MigratorData *migratorData = [[MigratorData alloc] initWithProjectSettingsPath:projectSettings.projectPath];

    MigrationController *migrationController = [[MigrationController alloc] init];
    migrationController.migrators = @[
       [[ProjectSettingsMigrator alloc] initWithMigratorData:migratorData toVersion:2],
       [[ResourcePathToPackageMigrator alloc] initWithMigratorData:migratorData],
       [[AllDocumentsMigrator alloc] initWithDirPath:migratorData.projectPath toVersion:5],
       [[AllPackageSettingsMigrator alloc] initWithMigratorData:migratorData toVersion:3],
       [[CCBToSBRenameMigrator alloc] initWithFilePath:migratorData.projectPath migratorData:migratorData]
    ];

    XCTAssertTrue([migrationController isMigrationRequired]);

    NSError *error;
    XCTAssertTrue([migrationController migrateWithError:&error]);
    XCTAssertNil(error);

    // Assertions: Project Settings
    [self assertFileDoesNotExist:[self fullPathForFile:@"foo.spritebuilder/foo.ccproj"]];
    NSDictionary *projectSettingsDict = [NSDictionary dictionaryWithContentsOfFile:[self fullPathForFile:@"foo.spritebuilder/foo.sbproj"]];
    XCTAssertEqualObjects(projectSettingsDict[CCB_DICTIONARY_KEY_FILEVERSION], @2);

    // Assertions: Documents
    [self assertFileDoesNotExist:[pathPackage1 stringByAppendingPathComponent:@"MainScene.ccb"]];
    [self assertFileDoesNotExist:[pathPackage2 stringByAppendingPathComponent:@"scenes/credits.ccb"]];

    [self assertFileExists:[pathPackage1 stringByAppendingPathComponent:@"MainScene.sb"]];
    [self assertFileExists:[pathPackage2 stringByAppendingPathComponent:@"scenes/credits.sb"]];

    NSDictionary *document1 = [NSDictionary dictionaryWithContentsOfFile:[self fullPathForFile:[pathPackage1 stringByAppendingPathComponent:@"MainScene.sb"]]];
    NSDictionary *document2 = [NSDictionary dictionaryWithContentsOfFile:[self fullPathForFile:[pathPackage2 stringByAppendingPathComponent:@"scenes/credits.sb"]]];
    XCTAssertEqualObjects(document1[CCB_DICTIONARY_KEY_FILEVERSION], @5);
    XCTAssertEqualObjects(document2[CCB_DICTIONARY_KEY_FILEVERSION], @5);

    // Assertions: Packages
    [self assertFileExists:pathPackage1PackageSettings];

    NSDictionary *migratedSettings = [NSDictionary dictionaryWithContentsOfFile:[self fullPathForFile:pathPackage2PackageSettings]];
    XCTAssertNotNil(migratedSettings);
    XCTAssertEqualObjects(migratedSettings[@"version"], @3);
}

- (void)testMigrationControllerWithOldProjectWithResourcePaths
{
    [self createEmptyFiles:@[
        @"foo.spritebuilder/SpriteBuilder Resources/asset.png",
        @"foo.spritebuilder/SpriteBuilder Resources/song.wav"]];

    ProjectSettings *projectSettings = [self createProjectSettingsFileWithName:@"foo.spritebuilder/foo.ccbproj"];
    XCTAssertTrue([projectSettings addPackageWithFullPath:[self fullPathForFile:@"foo.spritebuilder/SpriteBuilder Resources"] error:nil]);
    [projectSettings store];

    // Test
    MigratorData *migratorData = [[MigratorData alloc] initWithProjectSettingsPath:projectSettings.projectPath];

    MigrationController *migrationController = [[MigrationController alloc] init];
    migrationController.migrators = @[
       [[ProjectSettingsMigrator alloc] initWithMigratorData:migratorData toVersion:2],
       [[ResourcePathToPackageMigrator alloc] initWithMigratorData:migratorData],
       [[AllDocumentsMigrator alloc] initWithDirPath:migratorData.projectPath toVersion:5],
       [[AllPackageSettingsMigrator alloc] initWithMigratorData:migratorData toVersion:3],
       [[CCBToSBRenameMigrator alloc] initWithFilePath:migratorData.projectPath migratorData:migratorData]
    ];

    // migrationController.logger = [[MigrationLogger alloc] initWithLogToConsole:YES];

    XCTAssertTrue([migrationController isMigrationRequired]);

    NSError *error;
    XCTAssertTrue([migrationController migrateWithError:&error]);
    XCTAssertNil(error);

    [self assertFileDoesNotExist:[self fullPathForFile:@"foo.spritebuilder/foo.ccproj"]];
    [self assertFileExists:[self fullPathForFile:@"foo.spritebuilder/foo.sbproj"]];

    XCTAssertNotNil(projectSettings);
    [self assertFileExists:@"foo.spritebuilder/Packages/SpriteBuilder Resources.sbpack/asset.png"];
    [self assertFileExists:@"foo.spritebuilder/Packages/SpriteBuilder Resources.sbpack/song.wav"];
}

@end
