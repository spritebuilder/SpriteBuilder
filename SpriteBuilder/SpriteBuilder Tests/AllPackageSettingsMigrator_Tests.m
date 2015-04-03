//
//  AllPackageSettingsMigrator_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 16.02.15.
//
//


#import <XCTest/XCTest.h>
#import "FileSystemTestCase.h"
#import "ProjectSettings.h"
#import "AllPackageSettingsMigrator.h"
#import "MiscConstants.h"
#import "Errors.h"
#import "PackageSettings.h"
#import "RMPackage.h"
#import "PublishResolutions.h"
#import "MigratorData.h"

@interface AllPackageSettingsMigrator_Tests : FileSystemTestCase

@property (nonatomic, strong) AllPackageSettingsMigrator *migrator;
@property (nonatomic, strong) MigratorData *migratorData;

@end

@implementation AllPackageSettingsMigrator_Tests

- (void)setUp
{
    [super setUp];


    [self createFolders:@[
        @"foo.spritebuilder/Packages/package_a.sbpack",
        @"foo.spritebuilder/Packages/package_b.sbpack"]];

    NSArray *packagePaths = @[
            [self fullPathForFile:@"foo.spritebuilder/Packages/package_a.sbpack"],
            [self fullPathForFile:@"foo.spritebuilder/Packages/package_b.sbpack"]];

    self.migratorData = [[MigratorData alloc] initWithProjectSettingsPath:[self fullPathForFile:@"foo.spritebuilder"]];
    self.migrator = [[AllPackageSettingsMigrator alloc] initWithPackagePaths:packagePaths
                                                                   toVersion:PACKAGE_SETTINGS_VERSION];
}

- (void)testMigrationWithProjectFilePath
{
    ProjectSettings *projectSettings = [self createProjectSettingsFileWithName:@"foo.spritebuilder/packages/foo.sbpack"];

    [projectSettings addPackageWithFullPath:[self fullPathForFile:@"foo.spritebuilder/Packages/package_a.sbpack"] error:nil];
    [projectSettings addPackageWithFullPath:[self fullPathForFile:@"foo.spritebuilder/Packages/package_b.sbpack"] error:nil];
    [projectSettings store];

    MigratorData *migratorData = [[MigratorData alloc] initWithProjectSettingsPath:projectSettings.projectPath];
    self.migrator = [[AllPackageSettingsMigrator alloc] initWithMigratorData:migratorData toVersion:PACKAGE_SETTINGS_VERSION];

    XCTAssertTrue([_migrator isMigrationRequired]);

    NSError *error;
    XCTAssertTrue([_migrator migrateWithError:&error]);
    XCTAssertNil(error);

    [self assertFilesExistRelativeToDirectory:@"foo.spritebuilder/Packages" filesPaths:@[
        [@"package_a.sbpack" stringByAppendingPathComponent:PACKAGE_PUBLISH_SETTINGS_FILE_NAME],
        [@"package_b.sbpack" stringByAppendingPathComponent:PACKAGE_PUBLISH_SETTINGS_FILE_NAME]
    ]];
}

- (void)testCreateDefaultPackageSettingsIfNoneExists
{
    XCTAssertTrue([_migrator isMigrationRequired]);

    NSError *error;
    XCTAssertTrue([_migrator migrateWithError:&error]);
    XCTAssertNil(error);

    [self assertFilesExistRelativeToDirectory:@"foo.spritebuilder/Packages" filesPaths:@[
        [@"package_a.sbpack" stringByAppendingPathComponent:PACKAGE_PUBLISH_SETTINGS_FILE_NAME],
        [@"package_b.sbpack" stringByAppendingPathComponent:PACKAGE_PUBLISH_SETTINGS_FILE_NAME]
    ]];

    RMPackage *package = [[RMPackage alloc] init];
    package.dirPath = [self fullPathForFile:@"foo.spritebuilder/Packages/package_a.sbpack"];

    PackageSettings *packageSettings = [[PackageSettings alloc] initWithPackage:package];
    NSError *error2;
    XCTAssertTrue([packageSettings loadWithError:&error2]);

    XCTAssertFalse(packageSettings.mainProjectResolutions.resolution_1x);
    XCTAssertFalse(packageSettings.mainProjectResolutions.resolution_2x);
    XCTAssertTrue(packageSettings.mainProjectResolutions.resolution_4x);
}

- (void)testMigrateOnlyPackageSettings
{
    // The full test is in the PackageSettings_Tests, this is only needed to get isMigrationRequired to return YES
    NSDictionary *dict = @{
        @"publishToCustomDirectory" : @NO,
        @"publishToZip" : @NO,
        @"osSettings" : @{
            @"ios": @{
                @"audio_quality":@3,
                @"resolutions":@[@"phone", @"phonehd", @"tablet", @"tablethd"]

            },
            @"android": @{
                @"audio_quality":@5,
                @"resolutions":@[@"phone", @"phonehd", @"tablet", @"tablethd"]
            }
        },
        @"publishEnv" : @0,
        @"publishToMainProject" : @NO,
        @"outputDir" : @""
    };

    [self createFilesWithContents:@{
            [@"foo.spritebuilder/Packages/package_a.sbpack" stringByAppendingPathComponent:PACKAGE_PUBLISH_SETTINGS_FILE_NAME] : dict
    }];

    XCTAssertTrue([_migrator isMigrationRequired]);
};

- (void)testCannotCreateDefaultPackageSettingsIfNoneExists
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:[self fullPathForFile:@"foo.spritebuilder/Packages/package_a.sbpack"] error:nil];
    [fileManager removeItemAtPath:[self fullPathForFile:@"foo.spritebuilder/Packages/package_b.sbpack"] error:nil];

    XCTAssertTrue([_migrator isMigrationRequired]);

    NSError *error;
    XCTAssertFalse([_migrator migrateWithError:&error]);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, SBProjectMigrationError);

    [self assertFilesDoNotExistRelativeToDirectory:@"foo.spritebuilder/Packages" filesPaths:@[
        [@"package_a.sbpack" stringByAppendingPathComponent:PACKAGE_PUBLISH_SETTINGS_FILE_NAME],
        [@"package_b.sbpack" stringByAppendingPathComponent:PACKAGE_PUBLISH_SETTINGS_FILE_NAME]
    ]];
}

- (void)testMigrationNotRequired
{
    NSArray *packagePaths = @[[self fullPathForFile:@"foo.spritebuilder/Packages/package_a.sbpack"]];

    self.migrator = [[AllPackageSettingsMigrator alloc] initWithPackagePaths:packagePaths toVersion:PACKAGE_SETTINGS_VERSION];

    RMPackage *package = [[RMPackage alloc] init];
    package.dirPath = [self fullPathForFile:@"foo.spritebuilder/Packages/package_a.sbpack"];

    PackageSettings *packageSettings = [[PackageSettings alloc] initWithPackage:package];
    XCTAssertTrue([packageSettings store]);

    XCTAssertFalse([_migrator isMigrationRequired]);

    NSError *error;
    XCTAssertTrue([_migrator migrateWithError:&error]);
    XCTAssertNil(error);
}

- (void)testRollBackPackageSettingsCreated
{
    XCTAssertTrue([_migrator isMigrationRequired]);

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
    XCTAssertTrue([_migrator isMigrationRequired]);

    NSError *error;
    XCTAssertTrue([_migrator migrateWithError:&error]);
}

- (void)testMigrateAllPackagesThatRequireMigration
{
    XCTAssertTrue([_migrator isMigrationRequired]);

    // This test mainly ensure that all packages' settings are touched and differ after migration
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

    [self createFilesWithContents:@{
            [@"foo.spritebuilder/Packages/package_a.sbpack" stringByAppendingPathComponent:PACKAGE_PUBLISH_SETTINGS_FILE_NAME] : packageSettings,
            [@"foo.spritebuilder/Packages/package_b.sbpack" stringByAppendingPathComponent:PACKAGE_PUBLISH_SETTINGS_FILE_NAME] : packageSettings,
    }];

    NSError *error;
    XCTAssertTrue([_migrator migrateWithError:&error]);
    XCTAssertNil(error);

    [self assertContentsOfFilesNotEqual:@{
            [@"foo.spritebuilder/Packages/package_a.sbpack" stringByAppendingPathComponent:PACKAGE_PUBLISH_SETTINGS_FILE_NAME] : packageSettings,
            [@"foo.spritebuilder/Packages/package_a.sbpack" stringByAppendingPathComponent:PACKAGE_PUBLISH_SETTINGS_FILE_NAME] : packageSettings
    }];
};

@end
