//
//  CCBDictionaryReader_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 22.01.15.
//
//

#import <XCTest/XCTest.h>
#import "CCBDictionaryReader.h"

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

    [self assertNode:node hasProperties:@{
        @"position" : [NSValue valueWithPoint:CGPointMake(0.0, 1.0)],
        @"UUID" : [NSValue valueWithPoint:CGPointMake(0.0, 1.0)],

    }];

    XCTAssertEqual(node.children.count, 3);



    // NSLog(@"%@", [node recursiveDescription]);
};

- (void)assertNode:(CCNode *)node hasProperties:(NSDictionary *)properties
{
    for (NSString *key in properties)
    {
        id value = [node valueForKey:key];
        XCTAssertEqualObjects(properties[key], value, @"key %@", key);
    }
}

@end
