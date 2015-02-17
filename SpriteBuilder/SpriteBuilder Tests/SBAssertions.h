//
// Created by Nicky Weber on 10.02.15.
//

#import <Foundation/Foundation.h>


@interface SBAssertions : NSObject

+ (void)assertArraysAreEqualIgnoringOrder:(NSArray *)arrayA arrayB:(NSArray *)arrayB;

+ (void)assertEqualObjectsWithDiff:(id)objectA objectB:(id)objectB;

@end
