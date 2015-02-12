//
//  Cocos2dUpdater_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 12.02.15.
//
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "Cocos2dUpdater.h"
#import "ProjectSettings.h"
#import "AppDelegate.h"
#import "FileSystemTestCase.h"


@interface Cocos2dUpdater_Tests : FileSystemTestCase

@property (nonatomic, strong) Cocos2dUpdater *cocos2dUpdater;
@property (nonatomic, strong) ProjectSettings *projectSettings;
@property (nonatomic, strong) AppDelegate *appDelegate;

@end

@implementation Cocos2dUpdater_Tests

- (void)setUp
{
    [super setUp];

    self.projectSettings = [[ProjectSettings alloc] init];
    self.appDelegate = [OCMockObject niceMockForClass:[AppDelegate class]];

    self.cocos2dUpdater = [[Cocos2dUpdater alloc] initWithAppDelegate:_appDelegate projectSettings:_projectSettings];
}

- (void)testUpdateWithUserActionIgnoreThisVersion
{

}

- (void)testUpdateWithUserActionCancelUpdate
{

}

- (void)testUpdateWithNoVersionFile
{

}

- (void)testUpdateWithUpdateToDateVersion
{

}

- (void)testUpdateWithKnownOlderVersion
{

}

@end
