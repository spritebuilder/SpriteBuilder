//
//  PluginManager_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 15.10.14.
//
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "PlugInNode.h"
#import "FileSystemTestCase.h"

typedef NSDictionary *(^PropertiesBlock)();

@interface PluginNode_Tests : FileSystemTestCase

@property (nonatomic, copy) NSURL *testBuiltInPluginsURL;
@property (nonatomic, strong) id mainBundleMock;

@end


@implementation PluginNode_Tests

- (void)setUp
{
    [super setUp];

    self.mainBundleMock = [OCMockObject niceMockForClass:[NSBundle class]];
    self.testBuiltInPluginsURL = [NSURL fileURLWithPath:[self fullPathForFile:@"Contents/Plugins"]];
    [[[_mainBundleMock stub] andReturn:_testBuiltInPluginsURL] builtInPlugInsURL];
}

- (void)testInitWithBundle
{
    NSString *fullPathForPlugin = [self createPropertiesListForPluginName:@"TestNode" usingProperties:[self propertiesForTestNode]];

    NSBundle *testBundleNode = [NSBundle bundleWithPath:fullPathForPlugin];
    PlugInNode *plugin = [[PlugInNode alloc] initWithBundle:testBundleNode mainBundle:_mainBundleMock];

    XCTAssertEqualObjects(plugin.displayName, @"Node");
    XCTAssertEqualObjects(plugin.descr, @"A node");
    XCTAssertEqualObjects(plugin.nodeClassName, @"TestNode");
    XCTAssertEqualObjects(plugin.nodeEditorClassName, @"TestEditorNode");
    XCTAssertEqual(plugin.canBeRoot, YES);
    XCTAssertEqual(plugin.canHaveChildren, YES);
    XCTAssertEqual(plugin.ordering, 2000);

    [self assertPropertiesInPlugin:plugin properties:@{
        @"TestNode" : @{
            @"name" : @"TestNode",
            @"type" : @"Separator",
            @"dontSetInEditor" : @YES,
            @"displayName" : @"TestNode",
        },
        @"contentSize" : @{
            @"name" : @"contentSize",
            @"type" : @"Size",
            @"displayName" : @"Content size",
        },
        @"anchorPoint" : @{
            @"name" : @"anchorPoint",
            @"type" : @"Point",
            @"displayName" : @"Anchor point",
        }
    }];
}

- (void)testInitWithBundleInheritsFrom
{
    [self createPropertiesListForPluginName:@"TestNode" usingProperties:[self propertiesForTestNode]];
    NSString *fullPathForPluginSprite = [self createPropertiesListForPluginName:@"TestSprite" usingProperties:[self propertiesForTestSprite]];

    NSBundle *testBundleSprite = [NSBundle bundleWithPath:fullPathForPluginSprite];
    PlugInNode *plugin = [[PlugInNode alloc] initWithBundle:testBundleSprite mainBundle:_mainBundleMock];

    XCTAssertEqualObjects(plugin.displayName, @"Sprite");
    XCTAssertEqualObjects(plugin.descr, @"A Sprite");
    XCTAssertEqualObjects(plugin.nodeClassName, @"TestSprite");
    XCTAssertEqualObjects(plugin.nodeEditorClassName, @"TestEditorSprite");
    XCTAssertEqual(plugin.canHaveChildren, YES);
    XCTAssertEqual(plugin.ordering, 2001);

    [self assertPropertiesInPlugin:plugin properties:@{
        @"TestNode" : @{
            @"name" : @"TestNode",
            @"type" : @"Separator",
            @"dontSetInEditor" : @YES,
            @"displayName" : @"TestNode",
        },
        @"TestSprite" : @{
            @"name" : @"TestSprite",
            @"type" : @"Separator",
            @"dontSetInEditor" : @YES,
            @"displayName" : @"CCSprite",
        },
        @"contentSize" : @{
            @"readOnly" : @YES,
            @"name" : @"contentSize",
            @"type" : @"Size",
            @"displayName" : @"CONTENT SIZE",
        },
        @"anchorPoint" : @{
            @"name" : @"anchorPoint",
            @"type" : @"Point",
            @"displayName" : @"Anchor point",
        }
    }];
}

- (void)testInitWithBundleInheritsFromAndNoneType
{
    [self createPropertiesListForPluginName:@"TestNode" usingProperties:[self propertiesForTestNode]];
    NSString *fullPathForPluginSprite = [self createPropertiesListForPluginName:@"TestSprite" usingProperties:[self propertiesForTestSpriteWithNoneType]];

    NSBundle *testBundleSprite = [NSBundle bundleWithPath:fullPathForPluginSprite];
    PlugInNode *plugin = [[PlugInNode alloc] initWithBundle:testBundleSprite mainBundle:_mainBundleMock];

    [self assertPropertiesInPlugin:plugin properties:@{
        @"TestNode" : @{
            @"name" : @"TestNode",
            @"type" : @"Separator",
            @"dontSetInEditor" : @YES,
            @"displayName" : @"TestNode",
        },
        @"TestSprite" : @{
            @"name" : @"TestSprite",
            @"type" : @"Separator",
            @"dontSetInEditor" : @YES,
            @"displayName" : @"CCSprite",
        },
    }];
}

- (void)assertPropertiesInPlugin:(PlugInNode *)plugin properties:(NSDictionary *)expectedProperties
{
    XCTAssertEqual([plugin.nodePropertiesDict count], [expectedProperties count], @"Plugins property count(%lu) is not equal to expected count(%lu). Expected properties: %@, plugin's properties: %@",
                   [plugin.nodePropertiesDict count], [expectedProperties count], expectedProperties, plugin.nodePropertiesDict);

    for (NSString *propertyName in expectedProperties)
    {
        NSDictionary *pluginsProperty = plugin.nodePropertiesDict[propertyName];
        XCTAssertTrue([pluginsProperty isEqualToDictionary:expectedProperties[propertyName]], @"Exptected property with key \"%@\" and values: %@ is not equal to plugins property %@",
                      propertyName, expectedProperties[propertyName], pluginsProperty);

    }
}


#pragma mark - Fixtures

- (NSString *)createPropertiesListForPluginName:(NSString *)pluginName usingProperties:(NSDictionary *)properties
{
    NSString *REL_PATH_TEST_NODE = [NSString stringWithFormat:@"Contents/Plugins/%@.ccbPlugNode", pluginName];
    NSString *FULL_PATH_TEST_NODE = [self fullPathForFile:REL_PATH_TEST_NODE];

    [self createFolders:@[
            [REL_PATH_TEST_NODE stringByAppendingPathComponent:@"Contents/Resources"],
    ]];

    [properties writeToFile:[FULL_PATH_TEST_NODE stringByAppendingPathComponent:@"Contents/Resources/CCBPProperties.plist"] atomically:YES];

    return FULL_PATH_TEST_NODE;
}

- (NSDictionary *)propertiesForTestNode
{
    return
        @{
            @"description" : @"A node",
            @"ordering" : @2000,
            @"displayName" : @"Node",
            @"canHaveChildren" : @YES,
            @"className" : @"TestNode",
            @"editorClassName" : @"TestEditorNode",
            @"canBeRootNode" : @YES,
            @"properties" : @[
                @{
                    @"name" : @"TestNode",
                    @"type" : @"Separator",
                    @"dontSetInEditor" : @YES,
                    @"displayName" : @"TestNode",
                },
                @{
                    @"name" : @"contentSize",
                    @"type" : @"Size",
                    @"displayName" : @"Content size",
                },
                @{
                    @"name" : @"anchorPoint",
                    @"type" : @"Point",
                    @"displayName" : @"Anchor point",
                }
            ]
        };
}

- (NSDictionary *)propertiesForTestSprite
{
    return
        @{
            @"inheritsFrom" : @"TestNode",
            @"description" : @"A Sprite",
            @"ordering" : @2001,
            @"displayName" : @"Sprite",
            @"canHaveChildren" : @YES,
            @"className" : @"TestSprite",
            @"editorClassName" : @"TestEditorSprite",
            @"properties" : @[
                @{
                    @"name" : @"TestSprite",
                    @"type" : @"Separator",
                    @"dontSetInEditor" : @YES,
                    @"displayName" : @"CCSprite",
                },
            ],
            @"propertiesOverridden" : @[
                @{
                    @"readOnly" : @YES,
                    @"name" : @"contentSize",
                    @"type" : @"Size",
                    @"displayName" : @"CONTENT SIZE",
                },
            ]
        };
}

- (NSDictionary *)propertiesForTestSpriteWithNoneType
{
    return
        @{
            @"inheritsFrom" : @"TestNode",
            @"description" : @"A Sprite",
            @"ordering" : @2001,
            @"displayName" : @"Sprite",
            @"canHaveChildren" : @YES,
            @"className" : @"TestSprite",
            @"editorClassName" : @"TestEditorSprite",
            @"properties" : @[
                @{
                    @"name" : @"TestSprite",
                    @"type" : @"Separator",
                    @"dontSetInEditor" : @YES,
                    @"displayName" : @"CCSprite",
                },
            ],
            @"propertiesOverridden" : @[
                @{
                    @"name" : @"contentSize",
                    @"type" : @"None",
                },
                @{
                    @"name" : @"anchorPoint",
                    @"type" : @"None",
                },
            ]
        };
}

@end
