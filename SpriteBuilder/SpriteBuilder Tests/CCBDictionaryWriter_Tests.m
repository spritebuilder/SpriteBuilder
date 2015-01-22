//
//  CCBDictionaryWriter_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 22.01.15.
//
//

#import <XCTest/XCTest.h>
#import "FileSystemTestCase.h"
#import "PlugInManager.h"
#import "CCBDictionaryWriter.h"

@interface CCBDictionaryWriter_Tests : FileSystemTestCase

// @property (nonatomic, strong) CCBDictionaryWriter *ccbDictionaryWriter;

@end

@implementation CCBDictionaryWriter_Tests

- (void)setUp
{
    [super setUp];

    // self.ccbDictionaryWriter = [[CCBDictionaryWriter alloc] init];

    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testSerializeNode
{
    CCNode *node = [[PlugInManager sharedManager] createDefaultNodeOfType:@"CCNode"];
    CCNode *sprite = [[PlugInManager sharedManager] createDefaultNodeOfType:@"CCSprite"];

    [node addChild:sprite];

    NSMutableDictionary *result =  [CCBDictionaryWriter serializeNode:node];

    NSDictionary *expectedDict =
    @{
        @"memberVarAssignmentType" : @1,
        @"baseClass" : @"CCNode",
        @"displayName" : @"CCNode",
        @"children" : @[
            @{
                @"baseClass" : @"CCSprite",
                @"children" : @[],
                @"customClass" : @"",
                @"displayName" : @"CCSprite",
                @"memberVarAssignmentName" : @"",
                @"memberVarAssignmentType" : @1,
                @"properties" :
                @[
                    @{
                        @"name" : @"name",
                        @"type" : @"StringSimple",
                        @"value" : @""
                    },
                    @{
                        @"name" : @"position",
                        @"type" : @"Position",
                        @"value" : @[@0, @0, @0, @0, @0]
                    },
                    @{
                        @"name" : @"anchorPoint",
                        @"type" : @"Point",
                        @"value" : @[@0.5, @0.5]
                    },
                    @{
                        @"name" : @"scale",
                        @"type" : @"ScaleLock",
                        @"value" : @[@1, @1, @0, @0]
                    },
                    @{
                        @"name" : @"spriteFrame",
                        @"type" : @"SpriteFrame",
                        @"value" : @[@"", @""]
                    },
                    @{
                        @"name" : @"normalMapSpriteFrame",
                        @"type" : @"SpriteFrame",
                        @"value" : @[@"", @""]
                    },
                    @{
                        @"name" : @"color",
                        @"type" : @"Color3",
                        @"value" : @[@1, @1, @1, @1,]
                    },
                    @{
                        @"name" : @"effects",
                        @"type" : @"EffectControl",
                        @"value" : @[]
                    }
                ]
            }
        ],
        @"memberVarAssignmentName" : @"",
        @"customClass" : @"",
        @"properties" :
        @[
            @{
                @"name" : @"name",
                @"type" : @"StringSimple",
                @"value" : @""
            },
            @{
                @"name" : @"position",
                @"type" : @"Position",
                @"value" : @[@0, @0, @0, @0, @0]
            },
            @{
                @"name" : @"contentSize",
                @"type" : @"Size",
                @"value" : @[@0, @0, @0, @0]
            },
            @{
                @"name" : @"anchorPoint",
                @"type" : @"Point",
                @"value" : @[@0, @0]
            },
            @{
                @"name" : @"scale",
                @"type" : @"ScaleLock",
                @"value" : @[@1, @1, @0, @0]
            }
        ]
    };

    XCTAssertTrue([result isEqualTo:expectedDict], @"%@ does not equal %@", result, expectedDict);
};

@end
