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

@end


@implementation CCBDictionaryWriter_Tests

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
                        @"name" : @"blendMode",
                        @"type" : @"Blendmode",
                        @"value" : @{
                            @"CCBlendEquationAlpha" : @32774,
                            @"CCBlendEquationColor" : @32774,
                            @"CCBlendFuncDstAlpha" : @771,
                            @"CCBlendFuncDstColor" : @771,
                            @"CCBlendFuncSrcAlpha" : @1,
                            @"CCBlendFuncSrcColor" : @1
                        }
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

    [self assertEqualObjectsWithDiff:result objectB:expectedDict];
};

@end
