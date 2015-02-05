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
    _settings.resolution_4x = NO;
    XCTAssertTrue([_settings.resolutions containsObject:@(1)]);
    XCTAssertTrue([_settings.resolutions containsObject:@(2)]);
    XCTAssertFalse([_settings.resolutions containsObject:@(4)]);

    _settings.resolutions = @[@(4)];
    XCTAssertFalse(_settings.resolution_1x);
    XCTAssertFalse(_settings.resolution_2x);
    XCTAssertTrue(_settings.resolution_4x);
}

- (void)testDictionaryInitializerAndExport
{
    _settings.resolution_1x = NO;
    _settings.resolution_2x = YES;
    _settings.resolution_4x = YES;

    _settings.audio_quality = 7;

    NSDictionary *dict = [_settings toDictionary];

    PublishOSSettings *publishOSSettings = [[PublishOSSettings alloc] initWithDictionary:dict];
    XCTAssertFalse([publishOSSettings.resolutions containsObject:@(RESOLUTION_1X)]);
    XCTAssertTrue([publishOSSettings.resolutions containsObject:@(RESOLUTION_2X)]);
    XCTAssertTrue([publishOSSettings.resolutions containsObject:@(RESOLUTION_4X)]);

    XCTAssertEqual(publishOSSettings.audio_quality, 7);
}

@end
