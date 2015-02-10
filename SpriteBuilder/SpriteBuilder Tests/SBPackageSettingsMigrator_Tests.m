//
//  SBPackageSettingsMigrator_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 10.02.15.
//
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "SBPackageSettingsMigrator.h"
#import "SBErrors.h"
#import "SBAssertions.h"

@interface SBPackageSettingsMigrator_Tests : XCTestCase

@end

@implementation SBPackageSettingsMigrator_Tests

- (void)testCannotDowngrade
{
    NSDictionary *packageSettings = @{
        @"version" : @4
    };

    SBPackageSettingsMigrator *migrator = [[SBPackageSettingsMigrator alloc] initWithDictionary:packageSettings toVersion:3];

    NSError *error;
    XCTAssertNil([migrator migrate:&error]);

    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, SBPackageSettingsMigrationCannotDowngraderError);
};

- (void)testNoMigrationRule
{
    NSDictionary *packageSettings = @{
        @"version" : @1
    };

    SBPackageSettingsMigrator *migrator = [[SBPackageSettingsMigrator alloc] initWithDictionary:packageSettings toVersion:100];

    NSError *error;
    XCTAssertNil([migrator migrate:&error]);

    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, SBPackageSettingsMigrationNoRuleError);
}

- (void)testMigrateVersion_1_to_2
{
    // Version 1 was never tagged, so the key is not set
    NSDictionary *packageSettings = @{
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

    SBPackageSettingsMigrator *migrator = [[SBPackageSettingsMigrator alloc] initWithDictionary:packageSettings toVersion:2];


    NSError *error;
    NSDictionary *migratedSettings = [migrator migrate:&error];

    XCTAssertNotNil(migratedSettings);
    XCTAssertNil(error);

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

    SBPackageSettingsMigrator *migrator = [[SBPackageSettingsMigrator alloc] initWithDictionary:packageSettings toVersion:3];

    NSError *error;
    NSDictionary *migratedSettings = [migrator migrate:&error];

    XCTAssertNotNil(migratedSettings);
    XCTAssertNil(error);

    // Migrated values
    XCTAssertEqualObjects(migratedSettings[@"version"], @3);
    XCTAssertEqualObjects(migratedSettings[@"resourceAutoScaleFactor"], @4);

    NSArray *mainProjectResolutions = @[ @4 ];
    XCTAssertEqualObjects(migratedSettings[@"mainProjectResolutions"], mainProjectResolutions);

    [SBAssertions assertArraysAreEqualIgnoringOrder:migratedSettings[@"osSettings"][@"ios"][@"resolutions"] arrayB:@[@1, @2, @4]];
    [SBAssertions assertArraysAreEqualIgnoringOrder:migratedSettings[@"osSettings"][@"android"][@"resolutions"] arrayB:@[@1, @4]];

    // Values that should stay the same
    XCTAssertEqualObjects(migratedSettings[@"osSettings"][@"ios"][@"audio_quality"], @7);
    XCTAssertEqualObjects(migratedSettings[@"osSettings"][@"android"][@"audio_quality"], @2);

    XCTAssertEqualObjects(migratedSettings[@"publishToCustomDirectory"], @YES);
    XCTAssertEqualObjects(migratedSettings[@"publishToZip"], @YES);
    XCTAssertEqualObjects(migratedSettings[@"publishEnv"], @1);
    XCTAssertEqualObjects(migratedSettings[@"publishToMainProject"], @YES);
    XCTAssertEqualObjects(migratedSettings[@"outputDir"], @"asd");
}

@end
