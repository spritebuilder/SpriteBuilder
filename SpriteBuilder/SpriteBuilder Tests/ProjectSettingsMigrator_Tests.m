//
//  ProjectMigrator_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 25.08.14.
//
//

#import <XCTest/XCTest.h>
#import "ProjectSettings.h"
#import "ProjectSettingsMigrator.h"
#import "FileSystemTestCase.h"
#import "ResourcePropertyKeys.h"
#import "MigrationLogger.h"

@interface ProjectSettingsMigrator_Tests : FileSystemTestCase

@end


@implementation ProjectSettingsMigrator_Tests

- (void)testMigration
{
    ProjectSettings *projectSettings = [self createProjectSettingsFileWithName:@"foo.spritebuilder/foo"];

    [projectSettings setProperty:@1 forRelPath:@"flowers" andKey:RESOURCE_PROPERTY_LEGACY_KEEP_SPRITES_UNTRIMMED];
    [projectSettings setProperty:@YES forRelPath:@"flowers" andKey:RESOURCE_PROPERTY_IS_SMARTSHEET];
    [projectSettings markAsDirtyRelPath:@"flowers"];

    [projectSettings setProperty:@YES forRelPath:@"rocks" andKey:RESOURCE_PROPERTY_IS_SMARTSHEET];
    [projectSettings clearDirtyMarkerOfRelPath:@"rocks"];

    [projectSettings setProperty:@3 forRelPath:@"background.png" andKey:RESOURCE_PROPERTY_IOS_IMAGE_FORMAT];
    [projectSettings clearDirtyMarkerOfRelPath:@"background.png"];

    [projectSettings store];

    NSMutableDictionary *project = [[NSDictionary dictionaryWithContentsOfFile:projectSettings.projectPath] mutableCopy];
    project[@"onlyPublishCCBs"] = @NO;
    [project writeToFile:projectSettings.projectPath atomically:YES];

    NSMutableString *renameResult = [NSMutableString string];
    ProjectSettingsMigrator *migrator = [[ProjectSettingsMigrator alloc] initWithProjectFilePath:projectSettings
            .projectPath                                                            renameResult:renameResult];

    XCTAssertTrue([migrator isMigrationRequired]);

    NSError *error;
    XCTAssertTrue([migrator migrateWithError:&error]);
    XCTAssertNil(error);

    ProjectSettings *projectSettingsMigrated = [[ProjectSettings alloc] initWithFilepath:projectSettings.projectPath];

    XCTAssertEqualObjects([projectSettingsMigrated.projectPath pathExtension], @"sbproj");
    [self assertFileExists:@"foo.spritebuilder/foo.sbproj"];
    [self assertFileDoesNotExist:@"foo.spritebuilder/foo.ccbproj"];

    XCTAssertFalse([projectSettingsMigrated propertyForRelPath:@"flowers" andKey:RESOURCE_PROPERTY_LEGACY_KEEP_SPRITES_UNTRIMMED]);
    XCTAssertFalse([projectSettingsMigrated propertyForRelPath:@"flowers" andKey:RESOURCE_PROPERTY_TRIM_SPRITES]);
    XCTAssertTrue([projectSettingsMigrated isDirtyRelPath:@"flowers"]);

    XCTAssertFalse([projectSettingsMigrated propertyForRelPath:@"rocks" andKey:RESOURCE_PROPERTY_LEGACY_KEEP_SPRITES_UNTRIMMED]);
    XCTAssertFalse([projectSettingsMigrated propertyForRelPath:@"rocks" andKey:RESOURCE_PROPERTY_TRIM_SPRITES]);
    XCTAssertFalse([projectSettingsMigrated isDirtyRelPath:@"rocks"]);

    XCTAssertFalse([projectSettingsMigrated propertyForRelPath:@"background.png" andKey:RESOURCE_PROPERTY_LEGACY_KEEP_SPRITES_UNTRIMMED]);
    XCTAssertFalse([projectSettingsMigrated propertyForRelPath:@"background.png" andKey:RESOURCE_PROPERTY_TRIM_SPRITES]);
    XCTAssertFalse([projectSettingsMigrated isDirtyRelPath:@"background.png"]);

    XCTAssertEqualObjects(projectSettingsMigrated.exporter, @"sbi");

    NSDictionary *newProject = [NSDictionary dictionaryWithContentsOfFile:projectSettings.projectPath];
    XCTAssertNil(newProject[@"onlyPublishCCBs"]);

    XCTAssertEqualObjects(renameResult, projectSettings.projectPath);
}

- (void)testHtmlInfoText
{
    ProjectSettings *projectSettings = [self createProjectSettingsFileWithName:@"foo.spritebuilder/foo"];

    NSMutableString *renameResult = [NSMutableString string];
    ProjectSettingsMigrator *migrator = [[ProjectSettingsMigrator alloc] initWithProjectFilePath:projectSettings
            .projectPath                                                            renameResult:renameResult];

    XCTAssertNotNil([migrator htmlInfoText]);
}

- (void)testMigrationRequired_oldCCBProjName
{
    ProjectSettings *projectSettings = [self createProjectSettingsFileWithName:@"foo.spritebuilder/foo.ccbproj"];
    NSMutableString *renameResult = [NSMutableString string];
    ProjectSettingsMigrator *migrator = [[ProjectSettingsMigrator alloc] initWithProjectFilePath:projectSettings
            .projectPath                                                            renameResult:renameResult];

    XCTAssertTrue([migrator isMigrationRequired]);

    NSError *error;
    XCTAssertTrue([migrator migrateWithError:&error]);
    XCTAssertNil(error);

    [self assertFileExists:@"foo.spritebuilder/foo.sbproj"];
    [self assertFileDoesNotExist:@"foo.spritebuilder/foo.ccbproj"];
}

- (void)testMigrationRequired_obsoleteKeysSetInPropertyList
{
    ProjectSettings *projectSettings = [self createProjectSettingsFileWithName:@"foo.spritebuilder/foo.sbproj"];

    NSMutableDictionary *project = [[NSDictionary dictionaryWithContentsOfFile:projectSettings.projectPath] mutableCopy];
    project[@"onlyPublishCCBs"] = @NO;
    [project writeToFile:projectSettings.projectPath atomically:YES];

    NSMutableString *renameResult = [NSMutableString string];
    ProjectSettingsMigrator *migrator = [[ProjectSettingsMigrator alloc] initWithProjectFilePath:projectSettings
            .projectPath                                                            renameResult:renameResult];

    XCTAssertTrue([migrator isMigrationRequired]);
}

- (void)testMigrationNotRequired
{
    ProjectSettings *projectSettings = [self createProjectSettingsFileWithName:@"foo.spritebuilder/foo.sbproj"];

    NSMutableString *renameResult = [NSMutableString string];
    ProjectSettingsMigrator *migrator = [[ProjectSettingsMigrator alloc] initWithProjectFilePath:projectSettings
            .projectPath                                                            renameResult:renameResult];

    NSString *originalPrjSettingsFile = [NSString stringWithContentsOfFile:projectSettings.projectPath encoding:NSUTF8StringEncoding error:nil];

    XCTAssertFalse([migrator isMigrationRequired]);

    NSError *error;
    XCTAssertTrue([migrator migrateWithError:&error]);
    XCTAssertNil(error);

    NSString *hopefullyNotMigratedFile = [NSString stringWithContentsOfFile:projectSettings.projectPath encoding:NSUTF8StringEncoding error:nil];

    [self assertEqualObjectsWithDiff:originalPrjSettingsFile objectB:hopefullyNotMigratedFile];
}

- (void)testRollback
{
    ProjectSettings *projectSettings = [self createProjectSettingsFileWithName:@"foo.spritebuilder/foo.ccbproj"];
    [projectSettings setProperty:@1 forRelPath:@"flowers" andKey:RESOURCE_PROPERTY_LEGACY_KEEP_SPRITES_UNTRIMMED];
    [projectSettings setProperty:@YES forRelPath:@"flowers" andKey:RESOURCE_PROPERTY_IS_SMARTSHEET];
    [projectSettings markAsDirtyRelPath:@"flowers"];
    [projectSettings store];

    NSString *originalPrjSettingsFile = [NSString stringWithContentsOfFile:projectSettings.projectPath encoding:NSUTF8StringEncoding error:nil];

    NSMutableString *renameResult = [NSMutableString string];
    ProjectSettingsMigrator *migrator = [[ProjectSettingsMigrator alloc] initWithProjectFilePath:projectSettings
            .projectPath                                                            renameResult:renameResult];

    XCTAssertTrue([migrator isMigrationRequired]);

    NSError *error;
    XCTAssertTrue([migrator migrateWithError:&error]);
    XCTAssertNil(error);

    [self assertFileExists:@"foo.spritebuilder/foo.sbproj"];
    [self assertFileDoesNotExist:@"foo.spritebuilder/foo.ccbproj"];

    [migrator rollback];

    [self assertFileExists:@"foo.spritebuilder/foo.ccbproj"];
    [self assertFileDoesNotExist:@"foo.spritebuilder/foo.sbproj"];

    NSString *newPrjSettingsFile = [NSString stringWithContentsOfFile:projectSettings.projectPath encoding:NSUTF8StringEncoding error:nil];

    [self assertEqualObjectsWithDiff:originalPrjSettingsFile objectB:newPrjSettingsFile];
}

@end
