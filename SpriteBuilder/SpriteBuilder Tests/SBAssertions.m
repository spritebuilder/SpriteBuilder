#import "SBAssertions.h"

#import <XCTest/XCTest.h>

@implementation SBAssertions

+ (void)assertArraysAreEqualIgnoringOrder:(NSArray *)arrayA arrayB:(NSArray *)arrayB
{
    NSMutableArray *arrayAMutable = [arrayA mutableCopy];
    NSMutableArray *arrayBMutable = [arrayB mutableCopy];

    NSSortDescriptor *highestToLowest = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:NO];
    [arrayAMutable sortUsingDescriptors:@[highestToLowest]];
    [arrayBMutable sortUsingDescriptors:@[highestToLowest]];

    XCTAssertEqualObjects(arrayAMutable, arrayBMutable);
}

@end
