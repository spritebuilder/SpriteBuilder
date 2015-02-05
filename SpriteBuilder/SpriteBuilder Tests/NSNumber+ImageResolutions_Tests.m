//
//  NSNumber+ImageResolutions_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 30.01.15.
//
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "NSNumber+ImageResolutions.h"

@interface NSNumber_ImageResolutions_Tests : XCTestCase

@end

@implementation NSNumber_ImageResolutions_Tests

- (void)testResolutionTag
{
    XCTAssertEqualObjects([@0.0001 resolutionTag], @"-0.0001x");

    XCTAssertEqualObjects([@1.23 resolutionTag], @"-1.23x");

    XCTAssertEqualObjects([@1 resolutionTag], @"-1x");

    XCTAssertEqualObjects([@100 resolutionTag], @"-100x");

    XCTAssertNil([@0 resolutionTag]);
}

@end
