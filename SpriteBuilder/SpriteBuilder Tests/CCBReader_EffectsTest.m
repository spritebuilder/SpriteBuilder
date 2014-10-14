//
//  CCBReader_EffectsTest.m
//  SpriteBuilder
//
//  Created by John Twigg on 7/28/14.
//
//

#import <XCTest/XCTest.h>
#import "Cocos2dTestHelpers.h"
#import "CCBReader.h"

@interface CCBReader_EffectsTest : XCTestCase

@end

@implementation CCBReader_EffectsTest

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testCCBRenderTest
{
	NSData * animData = [Cocos2dTestHelpers readCCB:@"EffectTest1"];
	XCTAssertNotNil(animData, @"Can't find ccb File");
	if(!animData)
		return;
	
	CCBReader * reader = [CCBReader reader];
	CCNode * rootNode = [reader loadWithData:animData owner:nil];


}

@end
