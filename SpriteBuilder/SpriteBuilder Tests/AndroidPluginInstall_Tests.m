//
//  AndroidPluginInstall_Tests.m
//  SpriteBuilder
//
//  Created by John Twigg on 6/27/14.
//
//

#import <XCTest/XCTest.h>
#import "AndroidPluginInstaller.h"

@interface AndroidPluginInstall_Tests : XCTestCase

@end

@implementation AndroidPluginInstall_Tests

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

-(void)testVerifyInstallation
{
	AndroidPluginInstaller * installer = [AndroidPluginInstaller new];
//	XCTAssert([installer verifyPluginInstallation], @"Failed to verify installation");
}

-(void)testCleanInstallation
{
	AndroidPluginInstaller * installer = [AndroidPluginInstaller new];
	//XCTAssert([installer verifyPluginInstallation], @"Failed to verify installation");
}


-(void)testInstallPlugin
{
	AndroidPluginInstaller * installer = [AndroidPluginInstaller new];
	//XCTAssert([installer installPlugin], @"Failed to install");
}



@end
