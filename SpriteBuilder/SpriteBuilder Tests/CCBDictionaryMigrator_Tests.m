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
#import "FileSystemTestCase.h"


static NSString *DOCUMENT_FILENAME = @"document.ccb";

@interface CCBDictionaryMigrator_Tests : FileSystemTestCase

@end


@implementation CCBDictionaryMigrator_Tests

- (void)testMigrateCCBWithoutVersion
{
    NSDictionary *dictOriginal = [self createDocumentOnDisk:@{}];

    CCBDictionaryMigrator *migrator = [[CCBDictionaryMigrator alloc] initWithFilepath:[self fullPathForFile:DOCUMENT_FILENAME]
                                                                            toVersion:kCCBDictionaryFormatVersion];

    NSError *error;
    XCTAssertFalse([migrator migrateWithError:&error]);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, SBCCBMigrationNoVersionFoundError);

    [self assertEqualObjectsWithDiff:dictOriginal objectB:[self loadDocument]];
}

- (void)testMigrateCCBWithEmptyMigrationStepClassPrefixError
{
    NSDictionary *dictOriginal = [self createDocumentOnDisk:@{}];

    CCBDictionaryMigrator *migrator = [[CCBDictionaryMigrator alloc] initWithFilepath:[self fullPathForFile:DOCUMENT_FILENAME]
                                                                            toVersion:kCCBDictionaryFormatVersion];

    migrator.migrationStepClassPrefix = nil;

    NSError *error;
    XCTAssertFalse([migrator migrateWithError:&error]);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, SBCCBMigrationNoMigrationStepClassPrefixError);

    [self assertEqualObjectsWithDiff:dictOriginal objectB:[self loadDocument]];
}

- (void)testMigrateUpdatingVersionOnly
{
    NSDictionary *dictOriginal = [self createDocumentOnDisk:@{
            CCB_DICTIONARY_KEY_FILEVERSION : @2
    }];

    CCBDictionaryMigrator *migrator = [[CCBDictionaryMigrator alloc] initWithFilepath:[self fullPathForFile:DOCUMENT_FILENAME]
                                                                            toVersion:5];

    // this is mainly to not use any existing migration classes with this simple case
    migrator.migrationStepClassPrefix = @"SurelyNotExistingButThatsOk";

    NSError *error;
    XCTAssertTrue([migrator migrateWithError:&error]);
    XCTAssertNil(error);

    NSDictionary *migratedCCB = [self loadDocument];
    XCTAssertEqualObjects(migratedCCB[CCB_DICTIONARY_KEY_FILEVERSION], @5);

    XCTAssertNotEqualObjects(dictOriginal, migratedCCB);
}

- (void)testMigrate
{
    NSDictionary *dictOriginal = [self createDocumentOnDisk:@{
        CCB_DICTIONARY_KEY_FILEVERSION : @1,
        @"payload" : @{
            @"foo" : @"baa"
        }
    }];

    CCBDictionaryMigrator *migrator = [[CCBDictionaryMigrator alloc] initWithFilepath:[self fullPathForFile:DOCUMENT_FILENAME]
                                                                            toVersion:3];

    // See below for class stub
    migrator.migrationStepClassPrefix = @"CCBTestMigrationStep";

    NSError *error;
    XCTAssertTrue([migrator migrateWithError:&error]);
    NSDictionary *migratedCCB = [self loadDocument];

    XCTAssertEqualObjects(migratedCCB[CCB_DICTIONARY_KEY_FILEVERSION], @3);
    XCTAssertEqualObjects(migratedCCB[@"payload"], @"done!");
    XCTAssertNil(error);

    XCTAssertNotEqualObjects(dictOriginal, migratedCCB);
};

- (void)testMigrateFailingWithUnderlyingError
{
    NSDictionary *dictOriginal = [self createDocumentOnDisk:@{
        CCB_DICTIONARY_KEY_FILEVERSION : @4
    }];

    CCBDictionaryMigrator *migrator = [[CCBDictionaryMigrator alloc] initWithFilepath:[self fullPathForFile:DOCUMENT_FILENAME]
                                                                            toVersion:5];

    // See below for class stub
    migrator.migrationStepClassPrefix = @"CCBTestMigrationFailingStep";

    NSError *error;
    XCTAssertFalse([migrator migrateWithError:&error]);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, SBCCBMigrationError);

    NSError *underlyingError = error.userInfo[NSUnderlyingErrorKey];
    XCTAssertNotNil(underlyingError);
    // Error code generated in class stub CCBTestMigrationFailingStep below
    XCTAssertEqual(underlyingError.code, 1234567);

    [self assertEqualObjectsWithDiff:dictOriginal objectB:[self loadDocument]];
}

- (void)testRollback
{
    NSDictionary *dictOriginal = [self createDocumentOnDisk:@{
        CCB_DICTIONARY_KEY_FILEVERSION : @1,
        @"payload" : @{
            @"foo" : @"baa"
        }
    }];

    CCBDictionaryMigrator *migrator = [[CCBDictionaryMigrator alloc] initWithFilepath:[self fullPathForFile:DOCUMENT_FILENAME]
                                                                            toVersion:3];
    migrator.migrationStepClassPrefix = @"CCBTestMigrationStep";

    NSError *error;
    XCTAssertTrue([migrator migrateWithError:&error]);

    [migrator rollback];

    [self assertEqualObjectsWithDiff:dictOriginal objectB:[self loadDocument]];
}


#pragma mark - helpers

- (NSDictionary *)loadDocument
{
    NSDictionary *document = [NSDictionary dictionaryWithContentsOfFile:[self fullPathForFile:DOCUMENT_FILENAME]];
    XCTAssertNotNil(document);

    return document;
}

- (NSDictionary *)createDocumentOnDisk:(NSDictionary *)contentsOfFile
{
    [contentsOfFile writeToFile:[self fullPathForFile:DOCUMENT_FILENAME] atomically:YES];
    [self assertFileExists:DOCUMENT_FILENAME];

    return contentsOfFile;
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
