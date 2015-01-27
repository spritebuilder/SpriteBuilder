//
//  CCBDictionaryReader_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 22.01.15.
//
//

#import <XCTest/XCTest.h>
#import "CCBDictionaryReader.h"
#import "NodeInfo.h"
#import "CustomPropSetting.h"

@interface CCBDictionaryReader_Tests : XCTestCase

@end


@implementation CCBDictionaryReader_Tests

- (void)setUp
{
    [super setUp];
}

- (void)testNodeGraphFromDocumentDict_version_4_to_5_migration_new_blend_mode
{
    CCNode *node = [CCBDictionaryReader nodeGraphFromDocumentDictionary:[self loadCCBFile:@"test_ccbreader_migration_version_4_to_5"] parentSize:CGSizeMake(1024.0, 1024.0)];

    CCSprite *child3 = node.children[2];
    XCTAssertTrue([node.children[2] isKindOfClass:[CCSprite class]]);

    XCTAssertEqualObjects(child3.blendMode.options[@"CCBlendFuncSrcColor"], @774);
    XCTAssertEqualObjects(child3.blendMode.options[@"CCBlendFuncDstColor"], @772);
}

- (void)testNodeGraphFromDocumentDict_node
{
    CCNode *container = [CCBDictionaryReader nodeGraphFromDocumentDictionary:[self loadCCBFile:@"test_ccbreader_node"] parentSize:CGSizeMake(1024.0, 1024.0)];
    CCNode *node = container.children[0];

    XCTAssertEqual(node.visible, NO);

    XCTAssertEqualWithAccuracy(node.position.x, 0.176, 0.001);
    XCTAssertEqual(node.position.y, 200.0);

    XCTAssertEqual(node.positionType.corner, CCPositionReferenceCornerBottomLeft);
    XCTAssertEqual(node.positionType.xUnit, CCPositionUnitNormalized);
    XCTAssertEqual(node.positionType.yUnit, CCPositionUnitPoints);

    XCTAssertEqual(node.contentSize.width, 123.0);
    XCTAssertEqual(node.contentSize.height, 345.0);

    XCTAssertEqualWithAccuracy(node.scaleX, 1.1, 0.001);
    XCTAssertEqualWithAccuracy(node.scaleY, 1.1, 0.001);
    XCTAssertEqual(node.scaleType, CCScaleTypePoints);

    XCTAssertEqualWithAccuracy(node.anchorPoint.x, 0.6, 0.0001);
    XCTAssertEqualWithAccuracy(node.anchorPoint.y, 0.7, 0.0001);

    XCTAssertEqualObjects(node.name, @"Foobar");

    XCTAssertEqualWithAccuracy(node.skewX, 0.2, 0.001);
    XCTAssertEqualWithAccuracy(node.skewY, 0.5, 0.001);

    XCTAssertEqualWithAccuracy(node.rotation, 10.0, 0.001);

    XCTAssertEqualObjects([node.userObject extraProps][@"customClass"], @"MainScene");
    XCTAssertEqualObjects([node.userObject extraProps][@"UUID"], @1);
    XCTAssertEqualObjects([node.userObject extraProps][@"memberVarAssignmentType"], @1);

    CustomPropSetting *customPropSetting = [node.userObject customProperties][0];
    XCTAssertEqualObjects([customPropSetting name], @"myCustomProperty");
    XCTAssertEqualObjects([customPropSetting value], @"test");
}

- (void)testNodeGraphFromDocumentDict_sprite
{
    CCNode *container = [CCBDictionaryReader nodeGraphFromDocumentDictionary:[self loadCCBFile:@"test_ccbreader_sprite"] parentSize:CGSizeMake(1024.0, 1024.0)];
    CCSprite *sprite = container.children[0];

    XCTAssertTrue([container.children[0] isKindOfClass:[CCSprite class]]);

    XCTAssertEqualWithAccuracy(sprite.color.red, 0.082352, 0.001);
    XCTAssertEqualWithAccuracy(sprite.color.green, 0.77647, 0.001);
    XCTAssertEqualWithAccuracy(sprite.color.blue, 0.10588, 0.001);
    XCTAssertEqualWithAccuracy(sprite.color.alpha, 0.5, 0.001);

    XCTAssertTrue([sprite.effect isKindOfClass:[CCEffectStack class]]);
    NSArray *effects = [sprite valueForKey:@"effects"];
    XCTAssertTrue([effects[0] isKindOfClass:[CCEffectContrast class]]);
    CCEffectContrast *effectContrast = effects[0];
    XCTAssertEqualWithAccuracy(effectContrast.contrast, 0.6, 0.001);

    XCTAssertEqualObjects(sprite.blendMode.options[@"CCBlendFuncSrcColor"], @774);
    XCTAssertEqualObjects(sprite.blendMode.options[@"CCBlendFuncDstColor"], @772);
    XCTAssertEqualObjects(sprite.blendMode.options[@"CCBlendFuncSrcAlpha"], @774);
    XCTAssertEqualObjects(sprite.blendMode.options[@"CCBlendFuncDstAlpha"], @772);
    XCTAssertEqualObjects(sprite.blendMode.options[@"CCBlendEquationColor"], @32774);
    XCTAssertEqualObjects(sprite.blendMode.options[@"CCBlendEquationAlpha"], @32774);
}

/*
- (void)testNodeGraphFromDocumentDict_nodegradient
{
    CCNode *node = [CCBDictionaryReader nodeGraphFromDocumentDictionary:[self loadCCBFile:@"test_ccbreader_nodegradient"] parentSize:CGSizeMake(1024.0, 1024.0)];

    // Node Gradient
    CCNodeGradient *child1 = node.children[0];
    XCTAssertTrue([node.children[0] isKindOfClass:[CCNodeGradient class]]);

    XCTAssertEqualWithAccuracy([child1 color].red, 0.209, 0.001);
    XCTAssertEqualWithAccuracy([child1 color].green, 0.649, 0.001);
    XCTAssertEqualWithAccuracy([child1 color].blue, 0.870, 0.001);
    XCTAssertEqualWithAccuracy([child1 color].alpha, 1.0, 0.001);

    XCTAssertEqualWithAccuracy(child1.vector.x, 0.3, 0.001);
    XCTAssertEqualWithAccuracy(child1.vector.y, -0.4, 0.001);

    XCTAssertEqualWithAccuracy([child1 endColor].red, 0.129, 0.001);
    XCTAssertEqualWithAccuracy([child1 endColor].green, 0.5, 0.001);
    XCTAssertEqualWithAccuracy([child1 endColor].blue, 0.8, 0.001);
    XCTAssertEqualWithAccuracy([child1 endColor].alpha, 1.0, 0.001);
}

- (void)testNodeGraphFromDocumentDict_colornode
{
    CCNode *node = [CCBDictionaryReader nodeGraphFromDocumentDictionary:[self loadCCBFile:@"test_ccbreader_colornode"] parentSize:CGSizeMake(1024.0, 1024.0)];
}

- (void)testNodeGraphFromDocumentDict_sprite9slice
{
    CCNode *node = [CCBDictionaryReader nodeGraphFromDocumentDictionary:[self loadCCBFile:@"test_ccbreader_sprite9slice"] parentSize:CGSizeMake(1024.0, 1024.0)];
}

- (void)testNodeGraphFromDocumentDict_particlesystem
{
    CCNode *node = [CCBDictionaryReader nodeGraphFromDocumentDictionary:[self loadCCBFile:@"test_ccbreader_particlesystem"] parentSize:CGSizeMake(1024.0, 1024.0)];
}

- (void)testNodeGraphFromDocumentDict_labelttf
{
    CCNode *node = [CCBDictionaryReader nodeGraphFromDocumentDictionary:[self loadCCBFile:@"test_ccbreader_labeltff"] parentSize:CGSizeMake(1024.0, 1024.0)];
}

- (void)testNodeGraphFromDocumentDict_bmfont
{
    CCNode *node = [CCBDictionaryReader nodeGraphFromDocumentDictionary:[self loadCCBFile:@"test_ccbreader_bmfont"] parentSize:CGSizeMake(1024.0, 1024.0)];
}

- (void)testNodeGraphFromDocumentDict_button
{
    CCNode *node = [CCBDictionaryReader nodeGraphFromDocumentDictionary:[self loadCCBFile:@"test_ccbreader_button"] parentSize:CGSizeMake(1024.0, 1024.0)];
}

- (void)testNodeGraphFromDocumentDict_textfield
{
    CCNode *node = [CCBDictionaryReader nodeGraphFromDocumentDictionary:[self loadCCBFile:@"test_ccbreader_textfield"] parentSize:CGSizeMake(1024.0, 1024.0)];
}

- (void)testNodeGraphFromDocumentDict_slider
{
    CCNode *node = [CCBDictionaryReader nodeGraphFromDocumentDictionary:[self loadCCBFile:@"test_ccbreader_slider"] parentSize:CGSizeMake(1024.0, 1024.0)];
}

- (void)testNodeGraphFromDocumentDict_scrollview
{
    CCNode *node = [CCBDictionaryReader nodeGraphFromDocumentDictionary:[self loadCCBFile:@"test_ccbreader_scrollview"] parentSize:CGSizeMake(1024.0, 1024.0)];
}

- (void)testNodeGraphFromDocumentDict_boxlayout
{
    CCNode *node = [CCBDictionaryReader nodeGraphFromDocumentDictionary:[self loadCCBFile:@"test_ccbreader_boxlayout"] parentSize:CGSizeMake(1024.0, 1024.0)];
}

- (void)testNodeGraphFromDocumentDict_effectnode
{
    CCNode *node = [CCBDictionaryReader nodeGraphFromDocumentDictionary:[self loadCCBFile:@"test_ccbreader_effectnode"] parentSize:CGSizeMake(1024.0, 1024.0)];
}

- (void)testNodeGraphFromDocumentDict_subfile
{
    CCNode *node = [CCBDictionaryReader nodeGraphFromDocumentDictionary:[self loadCCBFile:@"test_ccbreader_subfile"] parentSize:CGSizeMake(1024.0, 1024.0)];
}
*/


#pragma mark - helper

- (NSDictionary *)loadCCBFile:(NSString *)ccbName
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *path = [bundle pathForResource:ccbName ofType:@"ccb"];

    XCTAssertNotNil(path, @"CCB file loading failed, no path found for ccb %@.ccb", ccbName);

    return [NSDictionary dictionaryWithContentsOfFile:path];
}

@end
