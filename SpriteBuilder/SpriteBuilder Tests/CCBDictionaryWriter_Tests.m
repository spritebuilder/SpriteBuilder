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

    BOOL equal = [result isEqualTo:expectedDict];
    XCTAssertTrue(equal);
    if (!equal)
    {
        NSLog(@"Diff:");
        [self diff:result dictB:expectedDict];
    }
};

- (void)diff:(NSDictionary *)dictA dictB:(NSDictionary *)dictB
{
    NSTask *task = [[NSTask alloc] init];
    [task setCurrentDirectoryPath:NSTemporaryDirectory()];
    [task setLaunchPath:@"/bin/bash"];

    NSArray *args = @[@"-c", [NSString stringWithFormat:@"/usr/bin/diff <(echo \"%@\") <(echo \"%@\")", dictA, dictB]];
    [task setArguments:args];

    @try
    {
        [task launch];
        [task waitUntilExit];
    }
    @catch (NSException *exception)
    {
        NSLog(@"[COCO2D-UPDATER] [ERROR] unzipping failed: %@", exception);
    }
}

@end
