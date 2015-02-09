//
//  PublishResolutions_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 09.02.15.
//
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "PublishResolutions.h"

@interface PublishResolutions_Tests : XCTestCase

@end

@implementation PublishResolutions_Tests

- (void)testInit
{
    PublishResolutions *publishResolutions = [[PublishResolutions alloc] init];

    XCTAssertFalse(publishResolutions.resolution_1x);
    XCTAssertFalse(publishResolutions.resolution_2x);
    XCTAssertTrue(publishResolutions.resolution_4x);
}

- (void)testInitWithDictionary
{
    NSDictionary *data = @{
        @"RESOLUTIONS_KEY_1X" : @YES,
        @"RESOLUTIONS_KEY_2X" : @YES,
        @"RESOLUTIONS_KEY_4X" : @NO,
    };

    PublishResolutions *publishResolutions = [[PublishResolutions alloc] initWithDictionary:data];

    XCTAssertTrue(publishResolutions.resolution_1x);
    XCTAssertTrue(publishResolutions.resolution_2x);
    XCTAssertFalse(publishResolutions.resolution_4x);
};

- (void)testToDictionary
{
    PublishResolutions *publishResolutions = [[PublishResolutions alloc] init];
    publishResolutions.resolution_1x = YES;
    publishResolutions.resolution_2x = NO;
    publishResolutions.resolution_4x = YES;

    NSDictionary *dict = [publishResolutions toDictionary];

    NSDictionary *expectation = @{
        @"RESOLUTIONS_KEY_1X" : @YES,
        @"RESOLUTIONS_KEY_2X" : @NO,
        @"RESOLUTIONS_KEY_4X" : @YES,
    };

    XCTAssertEqualObjects(expectation, dict);
}

- (void)testFastEnumeration
{
    PublishResolutions *publishResolutions = [[PublishResolutions alloc] init];
    publishResolutions.resolution_1x = YES;
    publishResolutions.resolution_2x = YES;
    publishResolutions.resolution_4x = YES;

    NSMutableArray *resolutionsFound = [NSMutableArray array];

    for (NSNumber *resolution in publishResolutions)
    {
        [resolutionsFound addObject:resolution];
    }

    XCTAssertTrue([resolutionsFound containsObject:@1]);
    XCTAssertTrue([resolutionsFound containsObject:@2]);
    XCTAssertTrue([resolutionsFound containsObject:@4]);
}

@end
