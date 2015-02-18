//
//  AllPackageSettingsMigrator_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 16.02.15.
//
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "FileSystemTestCase.h"
#import "ProjectSettings.h"
#import "AllPackageSettingsMigrator.h"
#import "MiscConstants.h"
#import "Errors.h"
#import "AssertionAddons.h"
#import "PackageSettings.h"

@interface AllPackageSettingsMigrator_Tests : FileSystemTestCase

@property (nonatomic, strong) AllPackageSettingsMigrator *migrator;
@property (nonatomic, strong) ProjectSettings *projectSettings;

@end

@implementation AllPackageSettingsMigrator_Tests

- (void)setUp
{
    [super setUp];

    [self createFolders:@[
        @"foo.spritebuilder/Packages/package_a.sbpack",
        @"foo.spritebuilder/Packages/package_b.sbpack"]];

    // Create some test packages
    self.projectSettings = [self createProjectSettingsFileWithName:@"foo.spritebuilder/foo"];

    [_projectSettings addResourcePath:[self fullPathForFile:@"foo.spritebuilder/Packages/package_a.sbpack"] error:nil];
    [_projectSettings addResourcePath:[self fullPathForFile:@"foo.spritebuilder/Packages/package_b.sbpack"] error:nil];

    self.migrator = [[AllPackageSettingsMigrator alloc] initWithProjectSettings:_projectSettings toVersion:PACKAGE_SETTINGS_VERSION];
}

- (void)testCreateDefaultPackageSettingsIfNoneExists
{
    NSError *error;
    XCTAssertTrue([_migrator migrateWithError:&error]);
    XCTAssertNil(error);

    [self assertFilesExistRelativeToDirectory:@"foo.spritebuilder/Packages" filesPaths:@[
        [@"package_a.sbpack" stringByAppendingPathComponent:PACKAGE_PUBLISH_SETTINGS_FILE_NAME],
        [@"package_b.sbpack" stringByAppendingPathComponent:PACKAGE_PUBLISH_SETTINGS_FILE_NAME]
    ]];
}

- (void)testCannotCreateDefaultPackageSettingsIfNoneExists
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:[self fullPathForFile:@"foo.spritebuilder/Packages/package_a.sbpack"] error:nil];
    [fileManager removeItemAtPath:[self fullPathForFile:@"foo.spritebuilder/Packages/package_b.sbpack"] error:nil];

    NSError *error;
    XCTAssertFalse([_migrator migrateWithError:&error]);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, SBProjectMigrationError);

    [self assertFilesDoNotExistRelativeToDirectory:@"foo.spritebuilder/Packages" filesPaths:@[
        [@"package_a.sbpack/" stringByAppendingPathComponent:PACKAGE_PUBLISH_SETTINGS_FILE_NAME],
        [@"package_b.sbpack/" stringByAppendingPathComponent:PACKAGE_PUBLISH_SETTINGS_FILE_NAME]
    ]];
}

- (void)testRollBackPackageSettingsCreated
{
    NSError *error;
    XCTAssertTrue([_migrator migrateWithError:&error]);

    [self assertFilesExistRelativeToDirectory:@"foo.spritebuilder/Packages" filesPaths:@[
        [@"package_a.sbpack" stringByAppendingPathComponent:PACKAGE_PUBLISH_SETTINGS_FILE_NAME],
        [@"package_b.sbpack" stringByAppendingPathComponent:PACKAGE_PUBLISH_SETTINGS_FILE_NAME]
    ]];

    [_migrator rollback];

    [self assertFilesDoNotExistRelativeToDirectory:@"foo.spritebuilder/Packages" filesPaths:@[
        [@"package_a.sbpack" stringByAppendingPathComponent:PACKAGE_PUBLISH_SETTINGS_FILE_NAME],
        [@"package_b.sbpack" stringByAppendingPathComponent:PACKAGE_PUBLISH_SETTINGS_FILE_NAME]
    ]];
}

- (void)testRollBackPackgeSettingsChanges
{
    NSError *error;
    XCTAssertTrue([_migrator migrateWithError:&error]);

}

- (void)testMigrateAllPackagesThatRequireMigration
{
    // This test mainly ensure that all packages' settings are touched
    // Details are tests in SBPackageSettingsMigrator_Tests
    NSDictionary *packageSettings = @{
        @"publishToCustomDirectory" : @YES,
        @"publishToZip" : @YES,
        @"osSettings" : @{
            @"ios": @{
                @"audio_quality":@7,
                @"resolutions":@[@"phone", @"phonehd", @"tablet", @"tablethd"]

            },
            @"android": @{
                @"audio_quality":@2,
                @"resolutions":@[@"phone", @"tablethd"]
            }
        },
        @"publishEnv" : @1,
        @"resourceAutoScaleFactor" : @-1,
        @"publishToMainProject" : @YES,
        @"outputDir" : @"asd"
    };

    NSString *path_a = [self fullPathForFile:[@"foo.spritebuilder/Packages/package_a.sbpack" stringByAppendingPathComponent:PACKAGE_PUBLISH_SETTINGS_FILE_NAME]];
    NSString *path_b = [self fullPathForFile:[@"foo.spritebuilder/Packages/package_b.sbpack" stringByAppendingPathComponent:PACKAGE_PUBLISH_SETTINGS_FILE_NAME]];

    [packageSettings writeToFile:path_a atomically:YES];
    [packageSettings writeToFile:path_b atomically:YES];

    NSError *error;
    XCTAssertTrue([_migrator migrateWithError:&error]);
    XCTAssertNil(error);

    NSDictionary *settings_a = [NSDictionary dictionaryWithContentsOfFile:path_a];
    NSDictionary *settings_b = [NSDictionary dictionaryWithContentsOfFile:path_b];

    XCTAssertNotNil(settings_a);
    XCTAssertNotNil(settings_b);

    [AssertionAddons assertEqualObjectsWithDiff:settings_a objectB:packageSettings];
    [AssertionAddons assertEqualObjectsWithDiff:settings_b objectB:packageSettings];
}

@end
