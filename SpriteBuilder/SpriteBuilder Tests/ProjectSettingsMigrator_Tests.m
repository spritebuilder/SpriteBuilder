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
#import "MigratorData.h"
#import "ResourcePropertyKeys.h"

@interface ProjectSettingsMigrator_Tests : FileSystemTestCase

@end


@implementation ProjectSettingsMigrator_Tests

- (void)testMigrationToVersion2
{
    ProjectSettings *projectSettings = [self createProjectSettingsFileWithName:@"foo.spritebuilder/foo"];
    MigratorData *migratorData = [[MigratorData alloc] initWithProjectSettingsPath:projectSettings.projectPath];

    [projectSettings setProperty:@1 forRelPath:@"flowers" andKey:RESOURCE_PROPERTY_DEPRECATED_KEEP_SPRITES_UNTRIMMED];
    [projectSettings setProperty:@YES forRelPath:@"flowers" andKey:RESOURCE_PROPERTY_IS_SMARTSHEET];
    [projectSettings markAsDirtyRelPath:@"flowers"];

    [projectSettings setProperty:@YES forRelPath:@"rocks" andKey:RESOURCE_PROPERTY_IS_SMARTSHEET];
    [projectSettings clearDirtyMarkerOfRelPath:@"rocks"];

    [projectSettings setProperty:@3 forRelPath:@"background.png" andKey:RESOURCE_PROPERTY_IOS_IMAGE_FORMAT];
    [projectSettings clearDirtyMarkerOfRelPath:@"background.png"];

    XCTAssertTrue([projectSettings addPackageWithFullPath:[self fullPathForFile:@"foo.spritebuilder/Packages/test.sbpack"] error:nil]);

    [projectSettings store];

    NSMutableDictionary *projectDictBeforeMigration = [[NSDictionary dictionaryWithContentsOfFile:projectSettings.projectPath] mutableCopy];
    projectDictBeforeMigration[PROJECTSETTINGS_KEY_DEPRECATED_RESOURCESPATHS] = @NO;
    projectDictBeforeMigration[PROJECTSETTINGS_KEY_DEPRECATED_EXCLUDEFROMPACKAGEMIGRATION] = @YES;
    projectDictBeforeMigration[PROJECTSETTINGS_KEY_DEPRECATED_ONLYPUBLISHCCBS] = @YES;
    projectDictBeforeMigration[PROJECTSETTINGS_KEY_DEPRECATED_PUBLISHDIR_IOS] = @"foo.spritebuilder/Published-IOS";
    projectDictBeforeMigration[PROJECTSETTINGS_KEY_DEPRECATED_ENGINE] = @0;
    projectDictBeforeMigration[PROJECTSETTINGS_KEY_FILEVERSION] = @1;
    projectDictBeforeMigration[PROJECTSETTINGS_KEY_RESOURCEPROPERTIES][@"background.png"][RESOURCE_PROPERTY_DEPRECATED_TABLETSCALE] = @1;

    [projectDictBeforeMigration writeToFile:projectSettings.projectPath atomically:YES];


    // Assertions
    ProjectSettingsMigrator *migrator = [[ProjectSettingsMigrator alloc] initWithMigratorData:migratorData toVersion:2];
    MigrationLogger *testLogger = [[MigrationLogger alloc] initWithLogToConsole:NO];
    [migrator setLogger:testLogger];
    XCTAssertTrue([migrator isMigrationRequired]);

    NSError *error;
    BOOL result = [migrator migrateWithError:&error];

    XCTAssert(result, @"Error in migration: %@ \n Log:%@",error.localizedDescription, testLogger.log);
    XCTAssertNil(error);

    ProjectSettings *projectSettingsMigrated = [[ProjectSettings alloc] initWithFilepath:projectSettings.projectPath];

    XCTAssertEqualObjects([projectSettingsMigrated.projectPath pathExtension], @"sbproj");
    [self assertFileExists:@"foo.spritebuilder/foo.sbproj"];
    [self assertFileDoesNotExist:@"foo.spritebuilder/foo.ccbproj"];

    XCTAssertFalse([projectSettingsMigrated propertyForRelPath:@"flowers" andKey:RESOURCE_PROPERTY_DEPRECATED_KEEP_SPRITES_UNTRIMMED]);
    XCTAssertFalse([projectSettingsMigrated propertyForRelPath:@"flowers" andKey:RESOURCE_PROPERTY_TRIM_SPRITES]);
    XCTAssertTrue([projectSettingsMigrated isDirtyRelPath:@"flowers"]);

    XCTAssertFalse([projectSettingsMigrated propertyForRelPath:@"rocks" andKey:RESOURCE_PROPERTY_DEPRECATED_KEEP_SPRITES_UNTRIMMED]);
    XCTAssertTrue([projectSettingsMigrated propertyForRelPath:@"rocks" andKey:RESOURCE_PROPERTY_TRIM_SPRITES]);
    XCTAssertFalse([projectSettingsMigrated isDirtyRelPath:@"rocks"]);

    XCTAssertFalse([projectSettingsMigrated propertyForRelPath:@"background.png" andKey:RESOURCE_PROPERTY_DEPRECATED_KEEP_SPRITES_UNTRIMMED]);
    XCTAssertFalse([projectSettingsMigrated propertyForRelPath:@"background.png" andKey:RESOURCE_PROPERTY_TRIM_SPRITES]);
    XCTAssertFalse([projectSettingsMigrated isDirtyRelPath:@"background.png"]);

    XCTAssertEqualObjects(projectSettingsMigrated.publishDirectoryIOS, @"foo.spritebuilder/Published-IOS");
    XCTAssertEqualObjects(projectSettingsMigrated.exporter, @"sbi");

    NSDictionary *newProject = [NSDictionary dictionaryWithContentsOfFile:projectSettings.projectPath];
    XCTAssertEqualObjects(newProject[PROJECTSETTINGS_KEY_FILEVERSION], @2);
    XCTAssertEqualObjects(newProject[PROJECTSETTINGS_KEY_PACKAGES],projectDictBeforeMigration[@"resourcePaths"]);
    XCTAssertNil(newProject[PROJECTSETTINGS_KEY_DEPRECATED_RESOURCESPATHS]);
    XCTAssertNil(newProject[PROJECTSETTINGS_KEY_DEPRECATED_EXCLUDEFROMPACKAGEMIGRATION]);
    XCTAssertNil(newProject[PROJECTSETTINGS_KEY_DEPRECATED_ONLYPUBLISHCCBS]);
    XCTAssertNil(newProject[PROJECTSETTINGS_KEY_DEPRECATED_ENGINE]);
    XCTAssertNil(newProject[PROJECTSETTINGS_KEY_DEPRECATED_PUBLISHDIR_IOS]);
    XCTAssertNil(newProject[PROJECTSETTINGS_KEY_RESOURCEPROPERTIES][@"background.png"][RESOURCE_PROPERTY_DEPRECATED_TABLETSCALE]);
}

- (void)testMigrationRequired_oldCCBProjName
{
    ProjectSettings *projectSettings = [self createProjectSettingsFileWithName:@"foo.spritebuilder/foo.ccbproj"];
    MigratorData *migratorData = [[MigratorData alloc] initWithProjectSettingsPath:projectSettings.projectPath];

    ProjectSettingsMigrator *migrator = [[ProjectSettingsMigrator alloc] initWithMigratorData:migratorData toVersion:kCCBProjectSettingsVersion];

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
    MigratorData *migratorData = [[MigratorData alloc] initWithProjectSettingsPath:projectSettings.projectPath];

    NSMutableDictionary *project = [[NSDictionary dictionaryWithContentsOfFile:projectSettings.projectPath] mutableCopy];
    project[@"onlyPublishCCBs"] = @NO;
    [project writeToFile:projectSettings.projectPath atomically:YES];

    ProjectSettingsMigrator *migrator = [[ProjectSettingsMigrator alloc] initWithMigratorData:migratorData toVersion:kCCBProjectSettingsVersion];

    XCTAssertTrue([migrator isMigrationRequired]);
}

- (void)testMigrationNotRequired
{
    ProjectSettings *projectSettings = [self createProjectSettingsFileWithName:@"foo.spritebuilder/foo.sbproj"];
    MigratorData *migratorData = [[MigratorData alloc] initWithProjectSettingsPath:projectSettings.projectPath];

    ProjectSettingsMigrator *migrator = [[ProjectSettingsMigrator alloc] initWithMigratorData:migratorData toVersion:kCCBProjectSettingsVersion];

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
    [projectSettings setProperty:@1 forRelPath:@"flowers" andKey:RESOURCE_PROPERTY_DEPRECATED_KEEP_SPRITES_UNTRIMMED];
    [projectSettings setProperty:@YES forRelPath:@"flowers" andKey:RESOURCE_PROPERTY_IS_SMARTSHEET];
    [projectSettings markAsDirtyRelPath:@"flowers"];
    [projectSettings store];

    MigratorData *migratorData = [[MigratorData alloc] initWithProjectSettingsPath:projectSettings.projectPath];

    NSString *originalPrjSettingsFile = [NSString stringWithContentsOfFile:projectSettings.projectPath encoding:NSUTF8StringEncoding error:nil];

    ProjectSettingsMigrator *migrator = [[ProjectSettingsMigrator alloc] initWithMigratorData:migratorData toVersion:kCCBProjectSettingsVersion];

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

    XCTAssertEqualObjects(migratorData.renamedFiles[[self fullPathForFile:@"foo.spritebuilder/foo.ccbproj"]],
                          [self fullPathForFile:@"foo.spritebuilder/foo.sbproj"]);
}

@end
