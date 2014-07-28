//
//  CCBReader.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 20.05.14.
//
//

#import <XCTest/XCTest.h>
#import "CCBXCocos2diPhoneWriter.h"
#import "CCBReader_Private.h"
#import "Cocos2dTestHelpers.h"

@interface CCBReader_Tests : XCTestCase

@end

@implementation CCBReader_Tests

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

- (void)testCCBVersionCompatibility
{
    XCTAssertEqual(kCCBVersion, kCCBXVersion, @"CCB version %d read by CCBReader is incompatible with version %d written by SpriteBuilder. Is cocos2d up to date?", kCCBVersion, kCCBXVersion);
}

@end
