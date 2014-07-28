//
//  FormatConvert_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 15.07.14.
//
//

#import <XCTest/XCTest.h>
#import "FCFormatConverter.h"

@interface FormatConvert_Tests : XCTestCase

@end

@implementation FormatConvert_Tests

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

// This test exists to ensure noone changes enum values by mistake that are persisted and have to
// be migrated with more effort to fix this change later on
- (void)testEnums
{
    XCTAssertEqual(kFCImageFormatPNG, 0, @"Enum value kFCImageFormatPNG  must not change");
    XCTAssertEqual(kFCImageFormatPNG_8BIT, 1, @"Enum value kFCImageFormatPNG_8BIT  must not change");
    XCTAssertEqual(kFCImageFormatPVR_RGBA8888, 2, @"Enum value kFCImageFormatPVR_RGBA8888  must not change");
    XCTAssertEqual(kFCImageFormatPVR_RGBA4444, 3, @"Enum value kFCImageFormatPVR_RGBA4444  must not change");
    XCTAssertEqual(kFCImageFormatPVR_RGB565, 4, @"Enum value kFCImageFormatPVR_RGB565  must not change");
    XCTAssertEqual(kFCImageFormatPVRTC_4BPP, 5, @"Enum value kFCImageFormatPVRTC_4BPP  must not change");
    XCTAssertEqual(kFCImageFormatPVRTC_2BPP, 6, @"Enum value kFCImageFormatPVRTC_2BPP  must not change");
    XCTAssertEqual(kFCImageFormatWEBP, 7, @"Enum value kFCImageFormatWEBP  must not change");
    XCTAssertEqual(kFCImageFormatJPG_High, 8, @"Enum value kFCImageFormatJPG_High  must not change");
    XCTAssertEqual(kFCImageFormatJPG_Medium, 9, @"Enum value kFCImageFormatJPG_Medium  must not change");
    XCTAssertEqual(kFCImageFormatJPG_Low, 10, @"Enum value kFCImageFormatJPG_Low  must not change");

    XCTAssertEqual(kFCSoundFormatCAF, 0, @"Enum value kFCSoundFormatCAF  must not change");
    XCTAssertEqual(kFCSoundFormatMP4, 1, @"Enum value kFCSoundFormatMP4  must not change");
    XCTAssertEqual(kFCSoundFormatOGG, 2, @"Enum value kFCSoundFormatOGG  must not change");
}

@end
