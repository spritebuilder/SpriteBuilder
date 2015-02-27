//
//  SBPackageSettingsMigrator_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 10.02.15.
//
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "PackageSettingsMigrator.h"
#import "Errors.h"
#import "FileSystemTestCase.h"
#import "RMPackage.h"
#import "PackageSettings.h"

@interface PackageSettingsMigrator_Tests : FileSystemTestCase

@end

@implementation PackageSettingsMigrator_Tests

- (void)testCannotDowngrade
{
    [self createPackageSettingsOnDisk:@{
            @"version" : @4
    }];

    PackageSettingsMigrator *migrator = [[PackageSettingsMigrator alloc] initWithFilepath:[self fullPathForFile:@"Package.plist"] toVersion:3];

    NSError *error;
    XCTAssertFalse([migrator migrateWithError:&error]);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, SBMigrationCannotDowngradeError);
};

- (void)testNoMigrationRule
{
    [self createPackageSettingsOnDisk:@{
            @"version" : @1
    }];

    PackageSettingsMigrator *migrator = [[PackageSettingsMigrator alloc] initWithFilepath:[self fullPathForFile:@"Package.plist"] toVersion:100];

    NSError *error;
    XCTAssertFalse([migrator migrateWithError:&error]);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, SBPackageSettingsMigrationNoRuleError);
}

- (void)testMigrateVersion_1_to_2
{
    // Version 1 was never tagged, so the key is not set
    [self createPackageSettingsOnDisk:@{
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
    }];

    PackageSettingsMigrator *migrator = [[PackageSettingsMigrator alloc] initWithFilepath:[self fullPathForFile:@"Package.plist"] toVersion:2];

    NSError *error;
    XCTAssertTrue([migrator migrateWithError:&error]);
    XCTAssertNil(error);

    NSDictionary *migratedSettings = [NSDictionary dictionaryWithContentsOfFile:[self fullPathForFile:@"Package.plist"]];
    XCTAssertNotNil(migratedSettings);

    // Migrated values
    XCTAssertEqualObjects(migratedSettings[@"version"], @2);
    XCTAssertEqualObjects(migratedSettings[@"resourceAutoScaleFactor"], @-1);

    // Values that should stay the same
    XCTAssertEqualObjects(migratedSettings[@"osSettings"][@"ios"][@"audio_quality"], @3);
    XCTAssertEqualObjects(migratedSettings[@"osSettings"][@"android"][@"audio_quality"], @5);

    XCTAssertEqualObjects(migratedSettings[@"publishToCustomDirectory"], @NO);
    XCTAssertEqualObjects(migratedSettings[@"publishToZip"], @NO);
    XCTAssertEqualObjects(migratedSettings[@"publishEnv"], @0);
    XCTAssertEqualObjects(migratedSettings[@"publishToMainProject"], @NO);
    XCTAssertEqualObjects(migratedSettings[@"outputDir"], @"");
}

- (void)testMigrateVersion_2_to_3
{
    [self createPackageSettingsOnDisk:@{
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
    }];

    PackageSettingsMigrator *migrator = [[PackageSettingsMigrator alloc] initWithFilepath:[self fullPathForFile:@"Package.plist"] toVersion:3];

    NSError *error;
    XCTAssertTrue([migrator migrateWithError:&error]);
    XCTAssertNil(error);

    NSDictionary *migratedSettings = [NSDictionary dictionaryWithContentsOfFile:[self fullPathForFile:@"Package.plist"]];
    XCTAssertNotNil(migratedSettings);

    // Migrated values
    XCTAssertEqualObjects(migratedSettings[@"version"], @3);
    XCTAssertEqualObjects(migratedSettings[@"resourceAutoScaleFactor"], @4);

    NSArray *mainProjectResolutions = @[ @4 ];
    XCTAssertEqualObjects(migratedSettings[@"mainProjectResolutions"], mainProjectResolutions);

    [self assertArraysAreEqualIgnoringOrder:migratedSettings[@"osSettings"][@"ios"][@"resolutions"] arrayB:@[@1, @2, @4]];
    [self assertArraysAreEqualIgnoringOrder:migratedSettings[@"osSettings"][@"android"][@"resolutions"] arrayB:@[@1, @4]];

    // Values that should stay the same
    XCTAssertEqualObjects(migratedSettings[@"osSettings"][@"ios"][@"audio_quality"], @7);
    XCTAssertEqualObjects(migratedSettings[@"osSettings"][@"android"][@"audio_quality"], @2);

    XCTAssertEqualObjects(migratedSettings[@"publishToCustomDirectory"], @YES);
    XCTAssertEqualObjects(migratedSettings[@"publishToZip"], @YES);
    XCTAssertEqualObjects(migratedSettings[@"publishEnv"], @1);
    XCTAssertEqualObjects(migratedSettings[@"publishToMainProject"], @YES);
    XCTAssertEqualObjects(migratedSettings[@"outputDir"], @"asd");
}

- (void)testRollback
{
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

    [self createPackageSettingsOnDisk:packageSettings];

    PackageSettingsMigrator *migrator = [[PackageSettingsMigrator alloc] initWithFilepath:[self fullPathForFile:@"Package.plist"] toVersion:3];

    NSError *error;
    XCTAssertTrue([migrator migrateWithError:&error]);
    XCTAssertNil(error);

    [migrator rollback];

    NSDictionary *migratedSettings = [NSDictionary dictionaryWithContentsOfFile:[self fullPathForFile:@"Package.plist"]];
    XCTAssertNotNil(migratedSettings);

    XCTAssertEqualObjects(packageSettings, migratedSettings);
}

- (void)testMigrationNotRequired
{
    [self createFolders:@[@"foo.spritebuilder/Packages/package_a.sbpack"]];

    RMPackage *package = [[RMPackage alloc] init];
    package.dirPath = [self fullPathForFile:@"foo.spritebuilder/Packages/package_a.sbpack"];

    PackageSettings *packageSettings = [[PackageSettings alloc] initWithPackage:package];
    XCTAssertTrue([packageSettings store]);

    PackageSettingsMigrator *migrator = [[PackageSettingsMigrator alloc] initWithFilepath:packageSettings.fullPath toVersion:PACKAGE_SETTINGS_VERSION];

    XCTAssertFalse([migrator isMigrationRequired]);

    NSError *error;
    XCTAssertTrue([migrator migrateWithError:&error]);
    XCTAssertNil(error);
}

#pragma mark - helpers

- (void)createPackageSettingsOnDisk:(NSDictionary *)contentsOfFile
{
    [contentsOfFile writeToFile:[self fullPathForFile:@"Package.plist"] atomically:YES];
    [self assertFileExists:@"Package.plist"];
}


@end
