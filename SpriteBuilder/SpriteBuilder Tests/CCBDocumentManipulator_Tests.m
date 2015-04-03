//
//  CCBDocumentManipulator_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 20.02.15.
//
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "CCBDocumentManipulator.h"
#import "CCBDictionaryKeys.h"

@interface CCBDocumentManipulator_Tests : XCTestCase

@end

@implementation CCBDocumentManipulator_Tests

- (void)testExample
{
    NSDictionary *doc = @{
        CCB_DICTIONARY_KEY_NODEGRAPH : @{
            CCB_DICTIONARY_KEY_PROPERTIES : @[
                    @{ @"name" : @"sprite" },
                    @{ @"baa" : @1 }
            ],
            CCB_DICTIONARY_KEY_CHILDREN : @[
                @{
                    CCB_DICTIONARY_KEY_PROPERTIES : @[
                        @{ @"ok" : @YES },
                        @{ @"spaceships" : @3 }
                    ]
                }
            ],
        }
    };

    NSMutableDictionary *mutableDoc = CFBridgingRelease(CFPropertyListCreateDeepCopy(NULL, (__bridge CFPropertyListRef)(doc), kCFPropertyListMutableContainersAndLeaves));

    CCBDocumentManipulator *manipulator = [[CCBDocumentManipulator alloc] initWithDocument:mutableDoc];

    [manipulator processAllProperties:^NSDictionary *(NSDictionary *property, NSDictionary *child)
    {
        return @{@"replaced" : @1};
    }];

    NSDictionary *expected = @{
        CCB_DICTIONARY_KEY_NODEGRAPH : @{
            CCB_DICTIONARY_KEY_PROPERTIES : @[
                    @{ @"replaced" : @1 },
                    @{ @"replaced" : @1 }
            ],
            CCB_DICTIONARY_KEY_CHILDREN : @[
                @{
                    CCB_DICTIONARY_KEY_PROPERTIES : @[
                        @{ @"replaced" : @1 },
                        @{ @"replaced" : @1 }
                    ]
                }
            ],
        }
    };

    XCTAssertEqualObjects(mutableDoc, expected);
};

@end
