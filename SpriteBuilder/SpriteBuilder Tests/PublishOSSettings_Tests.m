//
//  PublishOSSettings_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 22.07.14.
//
//

#import <XCTest/XCTest.h>
#import "PublishOSSettings.h"

@interface PublishOSSettings_Tests : XCTestCase

@property (nonatomic, strong) PublishOSSettings *settings;

@end


@implementation PublishOSSettings_Tests

- (void)setUp
{
    [super setUp];
    self.settings = [[PublishOSSettings alloc] init];
}

- (void)testExample
{
    _settings.resolution_tablethd = YES;
    XCTAssertTrue([_settings.resolutions containsObject:@"tablethd"]);
    XCTAssertFalse([_settings.resolutions containsObject:@"tablet"]);
    XCTAssertFalse([_settings.resolutions containsObject:@"phone"]);
    XCTAssertFalse([_settings.resolutions containsObject:@"phonehd"]);

    _settings.resolutions = @[@"tablethd", @"phonehd"];
    XCTAssertTrue(_settings.resolution_tablethd);
    XCTAssertTrue(_settings.resolution_phonehd);
    XCTAssertFalse(_settings.resolution_tablet);
    XCTAssertFalse(_settings.resolution_phone);
}

@end
