//
//  PackageSettings_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 21.07.14.
//
//

#import <XCTest/XCTest.h>
#import "PackagePublishSettings.h"
#import "RMPackage.h"
#import "PublishOSSettings.h"

@interface PackagePublishSettings_Tests : XCTestCase

@property (nonatomic, strong) RMPackage *package;
@property (nonatomic, strong) PackagePublishSettings *packageSettings;

@end

@implementation PackagePublishSettings_Tests

- (void)setUp
{
    [super setUp];

    self.package = [[RMPackage alloc] init];
    _package.dirPath = @"/foo/project.spritebuilder/Packages/mypackage.sbpack";

    self.packageSettings = [[PackagePublishSettings alloc] initWithPackage:_package];
}

- (void)testInitialValues
{
    PublishOSSettings *osSettingsIOS = [_packageSettings settingsForOsType:kCCBPublisherOSTypeIOS];
    XCTAssertNotNil(osSettingsIOS);

    PublishOSSettings *osSettingsIOSKVC = [_packageSettings valueForKeyPath:@"osSettings.ios"];
    XCTAssertNotNil(osSettingsIOSKVC);

    PublishOSSettings *osSettingsAndroid = [_packageSettings settingsForOsType:kCCBPublisherOSTypeAndroid];
    XCTAssertNotNil(osSettingsAndroid);

    PublishOSSettings *osSettingsAndroidKVC = [_packageSettings valueForKeyPath:@"osSettings.android"];
    XCTAssertNotNil(osSettingsAndroidKVC);
}

@end
