//
//  PublishOSSettings_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 22.07.14.
//
//

#import <XCTest/XCTest.h>
#import "PublishOSSettings.h"
#import "MiscConstants.h"

@interface PublishOSSettings_Tests : XCTestCase

@property (nonatomic, strong) PublishOSSettings *settings;

@end


@implementation PublishOSSettings_Tests

- (void)setUp
{
    [super setUp];
    self.settings = [[PublishOSSettings alloc] init];
}

- (void)testDefaultValuesAndSettingSome
{
    _settings.resolution_tablethd = NO;
    XCTAssertFalse([_settings.resolutions containsObject:@"tablethd"]);
    XCTAssertTrue([_settings.resolutions containsObject:@"tablet"]);
    XCTAssertTrue([_settings.resolutions containsObject:@"phone"]);
    XCTAssertTrue([_settings.resolutions containsObject:@"phonehd"]);

    _settings.resolutions = @[@"tablethd", @"phonehd"];
    XCTAssertTrue(_settings.resolution_tablethd);
    XCTAssertTrue(_settings.resolution_phonehd);
    XCTAssertFalse(_settings.resolution_tablet);
    XCTAssertFalse(_settings.resolution_phone);
}

- (void)testDictionaryInitializerAndExport
{
    _settings.resolution_tablet = NO;
    _settings.resolution_phonehd = NO;
    _settings.resolution_tablethd = YES;
    _settings.resolution_phone = YES;
    _settings.audio_quality = 7;

    NSDictionary *dict = [_settings toDictionary];

    PublishOSSettings *publishOSSettings = [[PublishOSSettings alloc] initWithDictionary:dict];
    XCTAssertTrue([publishOSSettings.resolutions containsObject:RESOLUTION_TABLET_HD]);
    XCTAssertTrue([publishOSSettings.resolutions containsObject:RESOLUTION_PHONE]);
    XCTAssertFalse([publishOSSettings.resolutions containsObject:RESOLUTION_TABLET]);
    XCTAssertFalse([publishOSSettings.resolutions containsObject:RESOLUTION_PHONE_HD]);

    XCTAssertEqual(publishOSSettings.audio_quality, 7);
}

@end
