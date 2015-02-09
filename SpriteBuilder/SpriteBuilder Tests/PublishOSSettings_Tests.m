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
#import "PublishResolutions.h"

@interface PublishOSSettings_Tests : XCTestCase

@property (nonatomic, strong) PublishOSSettings *settings;

@end


@implementation PublishOSSettings_Tests

- (void)setUp
{
    [super setUp];
    self.settings = [[PublishOSSettings alloc] init];
}

- (void)testDictionaryInitializerAndExport
{
    _settings.resolutions.resolution_1x = NO;
    _settings.resolutions.resolution_2x = YES;
    _settings.resolutions.resolution_4x = YES;

    _settings.audio_quality = 7;

    NSDictionary *dict = [_settings toDictionary];

    PublishOSSettings *publishOSSettings = [[PublishOSSettings alloc] initWithDictionary:dict];
    XCTAssertFalse(publishOSSettings.resolutions.resolution_1x);
    XCTAssertTrue(publishOSSettings.resolutions.resolution_2x);
    XCTAssertTrue(publishOSSettings.resolutions.resolution_4x);

    XCTAssertEqual(publishOSSettings.audio_quality, 7);
}

@end
