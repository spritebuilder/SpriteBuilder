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

@interface CCBDictionaryReader_Tests : XCTestCase

@property (nonatomic, strong) NSDictionary *documentDict;

@end


@implementation CCBDictionaryReader_Tests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.

    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *path = [bundle pathForResource:@"version_4" ofType:@"ccb"];

    self.documentDict = [NSDictionary dictionaryWithContentsOfFile:path];
}

- (void)testNodeGraphFromDocumentDict_version_4_to_5_migration_new_blend_mode
{
    CCNode *node = [CCBDictionaryReader nodeGraphFromDocumentDictionary:_documentDict parentSize:CGSizeMake(1024.0, 1024.0)];

    XCTAssertEqual(node.position.x, 100.0);
    XCTAssertEqual(node.position.y, 200.0);

    XCTAssertEqual(node.contentSize.width, 123.0);
    XCTAssertEqual(node.contentSize.height, 345.0);

    XCTAssertEqual(node.scaleX, 1.0);
    XCTAssertEqual(node.scaleY, 1.0);

    XCTAssertEqualWithAccuracy(node.anchorPoint.x, 0.6, 0.0001);
    XCTAssertEqualWithAccuracy(node.anchorPoint.y, 0.7, 0.0001);

    XCTAssertEqualObjects(node.name, @"Foobar");

    XCTAssertEqual(node.positionType.corner, CCPositionReferenceCornerBottomLeft);
    XCTAssertEqual(node.positionType.xUnit, CCPositionUnitNormalized);
    XCTAssertEqual(node.positionType.yUnit, CCPositionUnitPoints);

    XCTAssertEqualObjects([node.userObject extraProps][@"customClass"], @"MainScene");
    XCTAssertEqualObjects([node.userObject extraProps][@"UUID"], @1);
    XCTAssertEqualObjects([node.userObject extraProps][@"memberVarAssignmentType"], @1);

    XCTAssertEqual(node.children.count, 3);


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
    // XCTAssertEqual(, <#expression2, ...#>)
}

@end
