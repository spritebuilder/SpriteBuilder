//
//  CCBDictionaryMigrationStepVersion4_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 27.01.15.
//
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "CCBDictionaryMigrationStepVersion4.h"
#import "CCBDictionaryKeys.h"
#import "Errors.h"
#import "FileSystemTestCase+ProjectFixtures.h"

@interface CCBDictionaryMigrationStepVersion4_Tests : FileSystemTestCase

@property (nonatomic, strong) CCBDictionaryMigrationStepVersion4 *migrationStep;

@end

@implementation CCBDictionaryMigrationStepVersion4_Tests

- (void)setUp
{
    [super setUp];
    self.migrationStep = [[CCBDictionaryMigrationStepVersion4 alloc] init];
}

- (void)testMigrate
{
    NSDictionary *ccb = [self ccbVersion4WithOldBlendFunc];

    NSError *error;
    NSDictionary *migratedCCB = [_migrationStep migrate:ccb error:&error];

    XCTAssertNotNil(migratedCCB);
    XCTAssertNil(error);

    NSDictionary *expectedBlendModeProperty = @{
        CCB_DICTIONARY_KEY_PROPERTY_NAME : @"blendMode",
        CCB_DICTIONARY_KEY_PROPERTY_TYPE : @"Blendmode",
        CCB_DICTIONARY_KEY_PROPERTY_VALUE : @{
            @"CCBlendFuncSrcColor" : @774,
            @"CCBlendFuncSrcAlpha" : @774,
            @"CCBlendFuncDstAlpha" : @772,
            @"CCBlendFuncDstColor" : @772,
            @"CCBlendEquationColor" : @32774,
            @"CCBlendEquationAlpha" : @32774
        }
    };

    NSDictionary *expectedBlendModePropertyOfSecondChild = @{
        CCB_DICTIONARY_KEY_PROPERTY_NAME : @"blendMode",
        CCB_DICTIONARY_KEY_PROPERTY_TYPE : @"Blendmode",
        CCB_DICTIONARY_KEY_PROPERTY_VALUE : @{
            @"CCBlendFuncSrcColor" : @769,
            @"CCBlendFuncSrcAlpha" : @769,
            @"CCBlendFuncDstAlpha" : @771,
            @"CCBlendFuncDstColor" : @771,
            @"CCBlendEquationColor" : @32774,
            @"CCBlendEquationAlpha" : @32774
        }
    };

    NSDictionary *rootNodeBlendModeProperty = migratedCCB[CCB_DICTIONARY_KEY_NODEGRAPH][CCB_DICTIONARY_KEY_PROPERTIES][0];
    NSDictionary *firstChildsBlendModeProperty = migratedCCB[CCB_DICTIONARY_KEY_NODEGRAPH][CCB_DICTIONARY_KEY_CHILDREN][0][CCB_DICTIONARY_KEY_PROPERTIES][1];
    NSDictionary *secondChildsBlendModeProperty = migratedCCB[CCB_DICTIONARY_KEY_NODEGRAPH][CCB_DICTIONARY_KEY_CHILDREN][1][CCB_DICTIONARY_KEY_PROPERTIES][0];

    XCTAssertEqualObjects(rootNodeBlendModeProperty, expectedBlendModeProperty);
    XCTAssertEqualObjects(firstChildsBlendModeProperty[CCB_DICTIONARY_KEY_PROPERTY_NAME], @"blendFunc");
    XCTAssertEqualObjects(firstChildsBlendModeProperty[CCB_DICTIONARY_KEY_PROPERTY_VALUE], @"Not an array!");
    XCTAssertEqualObjects(secondChildsBlendModeProperty, expectedBlendModePropertyOfSecondChild);
}

- (void)testMigrateWithoutNodeGraph
{
    NSError *error;
    NSDictionary *migratedCCB = [_migrationStep migrate:@{@"foo" : @"baa"} error:&error];

    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, SBCCBMigrationError);
    XCTAssertNil(migratedCCB);
}

- (void)testMigrateWithNilParam
{
    NSError *error;
    NSDictionary *migratedCCB = [_migrationStep migrate:nil error:&error];

    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, SBCCBMigrationError);
    XCTAssertNil(migratedCCB);
}

@end
