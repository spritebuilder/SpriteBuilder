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

@property (nonatomic, strong) ProjectSettings *projectSettings;
@property (nonatomic, strong) ProjectSettingsMigrator *migrator;

@end

@implementation ProjectSettingsMigrator_Tests

- (void)setUp
{
    [super setUp];

    self.projectSettings = [self createProjectSettingsFileWithName:@"foo.spritebuilder/foo"];
    self.migrator = [[ProjectSettingsMigrator alloc] initWithProjectSettings:_projectSettings];
}

- (void)testMigration
{
    NSMutableDictionary *project = [[NSDictionary dictionaryWithContentsOfFile:_projectSettings.projectPath] mutableCopy];
    project[@"onlyPublishCCBs"] = @NO;
    [project writeToFile:_projectSettings.projectPath atomically:YES];

    [_projectSettings setProperty:@1 forRelPath:@"flowers" andKey:RESOURCE_PROPERTY_LEGACY_KEEP_SPRITES_UNTRIMMED];
    [_projectSettings setProperty:@YES forRelPath:@"flowers" andKey:RESOURCE_PROPERTY_IS_SMARTSHEET];
    [_projectSettings markAsDirtyRelPath:@"flowers"];

    [_projectSettings setProperty:@YES forRelPath:@"rocks" andKey:RESOURCE_PROPERTY_IS_SMARTSHEET];
    [_projectSettings clearDirtyMarkerOfRelPath:@"rocks"];

    [_projectSettings setProperty:@3 forRelPath:@"background.png" andKey:RESOURCE_PROPERTY_IOS_IMAGE_FORMAT];
    [_projectSettings clearDirtyMarkerOfRelPath:@"background.png"];

    XCTAssertTrue([_migrator isMigrationRequired]);

    NSError *error;
    XCTAssertTrue([_migrator migrateWithError:&error]);
    XCTAssertNil(error);

    XCTAssertEqualObjects([_projectSettings.projectPath pathExtension], @"sbproj");
    [self assertFileExists:@"foo.spritebuilder/foo.sbproj"];
    [self assertFileDoesNotExist:@"foo.spritebuilder/foo.ccbproj"];

    XCTAssertFalse([_projectSettings propertyForRelPath:@"flowers" andKey:RESOURCE_PROPERTY_LEGACY_KEEP_SPRITES_UNTRIMMED]);
    XCTAssertFalse([_projectSettings propertyForRelPath:@"flowers" andKey:RESOURCE_PROPERTY_TRIM_SPRITES]);
    XCTAssertTrue([_projectSettings isDirtyRelPath:@"flowers"]);

    XCTAssertFalse([_projectSettings propertyForRelPath:@"rocks" andKey:RESOURCE_PROPERTY_LEGACY_KEEP_SPRITES_UNTRIMMED]);
    XCTAssertFalse([_projectSettings propertyForRelPath:@"rocks" andKey:RESOURCE_PROPERTY_TRIM_SPRITES]);
    XCTAssertFalse([_projectSettings isDirtyRelPath:@"rocks"]);

    XCTAssertFalse([_projectSettings propertyForRelPath:@"background.png" andKey:RESOURCE_PROPERTY_LEGACY_KEEP_SPRITES_UNTRIMMED]);
    XCTAssertFalse([_projectSettings propertyForRelPath:@"background.png" andKey:RESOURCE_PROPERTY_TRIM_SPRITES]);
    XCTAssertFalse([_projectSettings isDirtyRelPath:@"background.png"]);

    XCTAssertEqualObjects(_projectSettings.exporter, @"sbi");

    NSDictionary *newProject = [NSDictionary dictionaryWithContentsOfFile:_projectSettings.projectPath];
    XCTAssertNil(newProject[@"onlyPublishCCBs"]);
}

- (void)testHtmlInfoText
{
    XCTAssertNotNil([_migrator htmlInfoText]);
}

- (void)testMigrationRequired_oldCCBProjName
{
    self.projectSettings = [self createProjectSettingsFileWithName:@"foo.spritebuilder/foo.ccbproj"];
    self.migrator = [[ProjectSettingsMigrator alloc] initWithProjectSettings:_projectSettings];

    XCTAssertTrue([_migrator isMigrationRequired]);
}

- (void)testMigrationRequired_obsoleteKeysSetInPropertyList
{
    self.projectSettings = [self createProjectSettingsFileWithName:@"foo.spritebuilder/foo.sbproj"];
    NSMutableDictionary *project = [[NSDictionary dictionaryWithContentsOfFile:[self fullPathForFile:@"foo.spritebuilder/foo.sbproj"]] mutableCopy];
    project[@"onlyPublishCCBs"] = @NO;
    [project writeToFile:[self fullPathForFile:@"foo.spritebuilder/foo.sbproj"] atomically:YES];

    self.migrator = [[ProjectSettingsMigrator alloc] initWithProjectSettings:_projectSettings];

    XCTAssertTrue([_migrator isMigrationRequired]);
}

- (void)testMigrationNotRequired
{
    self.projectSettings = [self createProjectSettingsFileWithName:@"foo.spritebuilder/foo.sbproj"];
    self.migrator = [[ProjectSettingsMigrator alloc] initWithProjectSettings:_projectSettings];

    NSString *originalPrjSettingsFile = [NSString stringWithContentsOfFile:_projectSettings.projectPath encoding:NSUTF8StringEncoding error:nil];

    XCTAssertFalse([_migrator isMigrationRequired]);

    NSError *error;
    XCTAssertTrue([_migrator migrateWithError:&error]);
    XCTAssertNil(error);

    NSString *hopefullyNotMigratedFile = [NSString stringWithContentsOfFile:_projectSettings.projectPath encoding:NSUTF8StringEncoding error:nil];

    [self assertEqualObjectsWithDiff:originalPrjSettingsFile objectB:hopefullyNotMigratedFile];
}

- (void)testRollback
{
    [_projectSettings setProperty:@1 forRelPath:@"flowers" andKey:RESOURCE_PROPERTY_LEGACY_KEEP_SPRITES_UNTRIMMED];
    [_projectSettings setProperty:@YES forRelPath:@"flowers" andKey:RESOURCE_PROPERTY_IS_SMARTSHEET];
    [_projectSettings markAsDirtyRelPath:@"flowers"];
    [_projectSettings store];

    NSString *originalPrjSettingsFile = [NSString stringWithContentsOfFile:_projectSettings.projectPath encoding:NSUTF8StringEncoding error:nil];

    XCTAssertTrue([_migrator isMigrationRequired]);

    NSError *error;
    XCTAssertTrue([_migrator migrateWithError:&error]);
    XCTAssertNil(error);

    XCTAssertEqualObjects([_projectSettings.projectPath pathExtension], @"sbproj");
    [self assertFileExists:@"foo.spritebuilder/foo.sbproj"];
    [self assertFileDoesNotExist:@"foo.spritebuilder/foo.ccbproj"];

    [_migrator rollback];

    XCTAssertEqualObjects([_projectSettings.projectPath pathExtension], @"ccbproj");
    [self assertFileExists:@"foo.spritebuilder/foo.ccbproj"];
    [self assertFileDoesNotExist:@"foo.spritebuilder/foo.sbproj"];

    NSString *newPrjSettingsFile = [NSString stringWithContentsOfFile:_projectSettings.projectPath encoding:NSUTF8StringEncoding error:nil];

    [self assertEqualObjectsWithDiff:originalPrjSettingsFile objectB:newPrjSettingsFile];
}

- (void)testRemovalOfKeys
{
    // onlyPublishCCBs -> remove
    // XCTFail(@"Implement me");
}

- (void)testRenamingOfProjectSettingsFile
{

}

@end
