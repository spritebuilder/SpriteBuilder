//
//  PackageSettings_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 21.07.14.
//
//

#import <XCTest/XCTest.h>
#import "PackageSettings.h"
#import "RMPackage.h"

@interface PackageSettings_Tests : XCTestCase

@property (nonatomic, strong) RMPackage *package;
@property (nonatomic, strong) PackageSettings *packageSettings;

@end

@implementation PackageSettings_Tests

- (void)setUp
{
    [super setUp];

    self.package = [[RMPackage alloc] init];
    _package.dirPath = @"/foo/project.spritebuilder/Packages/mypackage.sbpack";

    self.packageSettings = [[PackageSettings alloc] initWithPackage:_package];
}

- (void)testPublishingEnabledForOsTypes
{
    [_packageSettings setPublishEnabled:YES forOSType:kCCBPublisherOSTypeIOS];
    [_packageSettings setPublishEnabled:YES forOSType:kCCBPublisherOSTypeAndroid];

    XCTAssertTrue([_packageSettings isPublishEnabledForOSType:kCCBPublisherOSTypeIOS]);
    XCTAssertTrue([_packageSettings isPublishEnabledForOSType:kCCBPublisherOSTypeAndroid]);

    [_packageSettings setPublishEnabled:NO forOSType:kCCBPublisherOSTypeAndroid];

    XCTAssertFalse([_packageSettings isPublishEnabledForOSType:kCCBPublisherOSTypeAndroid]);
}

- (void)testPublishResolutions
{
    [_packageSettings setPublishResolutions:@[@"tablethd", @"phone"] forOSType:kCCBPublisherOSTypeIOS];
    [_packageSettings setPublishResolutions:@[@"tablet", @"phonehd"] forOSType:kCCBPublisherOSTypeAndroid];

    NSArray *arr1 = @[@"tablethd", @"phone"];
    XCTAssertTrue([[_packageSettings publishResolutionsForOSType:kCCBPublisherOSTypeIOS] isEqualToArray:arr1]);

    NSArray *arr2 = @[@"tablet", @"phonehd"];
    XCTAssertTrue([[_packageSettings publishResolutionsForOSType:kCCBPublisherOSTypeIOS] isEqualToArray:arr2]);
}

@end
