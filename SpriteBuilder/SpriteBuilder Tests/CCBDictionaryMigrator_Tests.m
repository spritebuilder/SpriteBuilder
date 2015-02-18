//
//  CCBDictionaryMigrator_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 26.01.15.
//
//

#import <XCTest/XCTest.h>
#import "CCBDictionaryMigrator.h"
#import "Errors.h"
#import "CCBDictionaryKeys.h"
#import "CCBDictionaryMigrationProtocol.h"
#import "NSError+SBErrors.h"
#import "CCBDictionaryReader.h"

@interface CCBDictionaryMigrator_Tests : XCTestCase

@end


@implementation CCBDictionaryMigrator_Tests

- (void)testMigrateCCBWithoutVersion
{
    CCBDictionaryMigrator *migrator = [[CCBDictionaryMigrator alloc] initWithCCB:@{} toVersion:kCCBDictionaryFormatVersion];

    NSError *error;
    NSDictionary *migratedCCB = [migrator migrate:&error];

    XCTAssertNil(migratedCCB);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, SBCCBMigrationNoVersionFoundError);
};

- (void)testMigrateCCBWithEmptyMigrationStepClassPrefixError
{
    CCBDictionaryMigrator *migrator = [[CCBDictionaryMigrator alloc] initWithCCB:@{} toVersion:kCCBDictionaryFormatVersion];
    migrator.migrationStepClassPrefix = nil;

    NSError *error;
    NSDictionary *migratedCCB = [migrator migrate:&error];

    XCTAssertNil(migratedCCB);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, SBCCBMigrationNoMigrationStepClassPrefixError);
};

- (void)testMigrateUpdatingVersionOnly
{
    NSDictionary *ccb = @{
        CCB_DICTIONARY_KEY_FILEVERSION : @2
    };

    CCBDictionaryMigrator *migrator = [[CCBDictionaryMigrator alloc] initWithCCB:ccb toVersion:5];
    migrator.migrationStepClassPrefix = @"SurelyNotExistingButThatsOk";

    NSError *error;
    NSDictionary *migratedCCB = [migrator migrate:&error];

    XCTAssertNotNil(migratedCCB);
    XCTAssertEqualObjects(migratedCCB[CCB_DICTIONARY_KEY_FILEVERSION], @5);
    XCTAssertNil(error);
}

- (void)testMigrate
{
    NSDictionary *ccb = @{
        CCB_DICTIONARY_KEY_FILEVERSION : @1,
        @"payload" : @{
            @"foo" : @"baa"
        }
    };

    CCBDictionaryMigrator *migrator = [[CCBDictionaryMigrator alloc] initWithCCB:ccb toVersion:3];
    // See below for class stub
    migrator.migrationStepClassPrefix = @"CCBTestMigrationStep";

    NSError *error;
    NSDictionary *migratedCCB = [migrator migrate:&error];

    XCTAssertNotNil(migratedCCB);
    XCTAssertEqualObjects(migratedCCB[CCB_DICTIONARY_KEY_FILEVERSION], @3);
    XCTAssertEqualObjects(migratedCCB[@"payload"], @"done!");
    XCTAssertNil(error);
};

- (void)testMigrateFailingWithUnderlyingError
{
    NSDictionary *ccb = @{
        CCB_DICTIONARY_KEY_FILEVERSION : @4
    };

    CCBDictionaryMigrator *migrator = [[CCBDictionaryMigrator alloc] initWithCCB:ccb toVersion:5];
    // See below for class stub
    migrator.migrationStepClassPrefix = @"CCBTestMigrationFailingStep";

    NSError *error;
    NSDictionary *migratedCCB = [migrator migrate:&error];

    XCTAssertNil(migratedCCB);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, SBCCBMigrationError);

    NSLog(@"%@", error);

    NSError *underlyingError = error.userInfo[NSUnderlyingErrorKey];
    XCTAssertNotNil(underlyingError);
    XCTAssertEqual(underlyingError.code, 1234567);
}

@end


#pragma mark - migration step classes

@interface CCBTestMigrationStep2 : NSObject <CCBDictionaryMigrationProtocol>

@end

@implementation CCBTestMigrationStep2

- (NSDictionary *)migrate:(NSDictionary *)ccb error:(NSError **)error
{
    NSMutableDictionary *mutableCCB = CFBridgingRelease(CFPropertyListCreateDeepCopy(NULL, (__bridge CFPropertyListRef)(ccb), kCFPropertyListMutableContainersAndLeaves));
    mutableCCB[@"payload"] = @"done!";

    return mutableCCB;
}

@end



@interface CCBTestMigrationFailingStep4 : NSObject <CCBDictionaryMigrationProtocol>

@end

@implementation CCBTestMigrationFailingStep4

- (NSDictionary *)migrate:(NSDictionary *)ccb error:(NSError **)error
{
    [NSError setNewErrorWithErrorPointer:error code:1234567 message:@"Some arbitrary error"];

    return nil;
}

@end
