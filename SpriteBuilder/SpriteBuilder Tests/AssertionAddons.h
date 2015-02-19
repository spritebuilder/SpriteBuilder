//
// Created by Nicky Weber on 10.02.15.
//

#import <Foundation/Foundation.h>


@interface AssertionAddons : NSObject

// This method will actually sort both arrays with the same sort descriptor and then compare so
// original ordering is not significant for comparison reasons.
+ (void)assertArraysAreEqualIgnoringOrder:(NSArray *)arrayA arrayB:(NSArray *)arrayB;

// Works like XCTAssertEqualObjects but is intended to work with larger data structures or strings
// which will clutter your log if both objects are not the same. This method will only dump a diff to log.
+ (void)assertEqualObjectsWithDiff:(id)objectA objectB:(id)objectB;

@end
