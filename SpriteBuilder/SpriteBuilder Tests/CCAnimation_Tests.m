//
//  CCAnimation_Tests.m
//  SpriteBuilder
//
//  Created by John Twigg on 6/9/14.
//
//

#import <XCTest/XCTest.h>
#import "cocos2d.h"
#import "CCBXCocos2diPhone.h"
#import "PlugInManager.h"
#import "PlugInExport.h"
#import "CCBReader.h"

@interface CCAnimation_Tests : XCTestCase

@end

@implementation CCAnimation_Tests

-(NSData*)writeCCB:(NSString*)srcFileName
{
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSString *path = [bundle pathForResource:srcFileName ofType:@"ccb"];
	NSDictionary *  doc  = [NSDictionary dictionaryWithContentsOfFile:path];
	
	PlugInExport *plugIn = [[PlugInManager sharedManager] plugInExportForExtension:@"ccbi"];
	NSData *data = [plugIn exportDocument:doc];
	return data;
}

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

- (void)testExample
{
	NSData * animData = [self writeCCB:@"AnimationTest1"];

	CCBReader * reader = [CCBReader reader];
	CCNode * node = [reader loadWithData:animData owner:self];
	 
}

@end
