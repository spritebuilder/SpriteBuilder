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
#import "PublishOSSettings.h"
#import "FileSystemTestCase.h"
#import "MiscConstants.h"
#import "CCBPublisherTypes.h"
#import "PublishResolutions.h"
#import "Errors.h"


@interface PackageSettings_Tests : FileSystemTestCase

@property (nonatomic, strong) RMPackage *package;
@property (nonatomic, strong) PackageSettings *packageSettings;

@end


@implementation PackageSettings_Tests

- (void)setUp
{
    [super setUp];

    self.package = [[RMPackage alloc] init];
    _package.dirPath = [self fullPathForFile:@"foo/project.spritebuilder/Packages/mypackage.sbpack"];

    self.packageSettings = [[PackageSettings alloc] initWithPackage:_package];

    [self createFolders:@[@"foo/project.spritebuilder/Packages/mypackage.sbpack"]];
}

- (void)testInitialValuesAndKVCPaths
{
    XCTAssertTrue(_packageSettings.publishToMainProject);
    XCTAssertFalse(_packageSettings.publishToZip);
    XCTAssertFalse(_packageSettings.publishToCustomOutputDirectory);

    PublishOSSettings *osSettingsIOS = [_packageSettings settingsForOsType:kCCBPublisherOSTypeIOS];
    XCTAssertNotNil(osSettingsIOS);

    PublishOSSettings *osSettingsIOSKVC = [_packageSettings valueForKeyPath:@"osSettings.ios"];
    XCTAssertNotNil(osSettingsIOSKVC);

    PublishOSSettings *osSettingsAndroid = [_packageSettings settingsForOsType:kCCBPublisherOSTypeAndroid];
    XCTAssertNotNil(osSettingsAndroid);

    PublishOSSettings *osSettingsAndroidKVC = [_packageSettings valueForKeyPath:@"osSettings.android"];
    XCTAssertNotNil(osSettingsAndroidKVC);
}

- (void)testPersistency
{
    _packageSettings.customOutputDirectory = @"foo";
    _packageSettings.publishToMainProject = NO;
    _packageSettings.publishToZip = NO;
    _packageSettings.publishToCustomOutputDirectory = YES;
    _packageSettings.publishEnvironment = kCCBPublishEnvironmentRelease;
    _packageSettings.resourceAutoScaleFactor = 3;

    _packageSettings.mainProjectResolutions.resolution_1x = YES;
    _packageSettings.mainProjectResolutions.resolution_2x = YES;
    _packageSettings.mainProjectResolutions.resolution_4x = NO;

    PublishOSSettings *osSettingsIOS = [_packageSettings settingsForOsType:kCCBPublisherOSTypeIOS];
    osSettingsIOS.audio_quality = 8;
    osSettingsIOS.resolutions.resolution_1x = YES;
    osSettingsIOS.resolutions.resolution_2x = NO;
    osSettingsIOS.resolutions.resolution_4x = NO;
    [_packageSettings setOSSettings:osSettingsIOS forOsType:kCCBPublisherOSTypeIOS];

    PublishOSSettings *osSettingsAndroid = [_packageSettings settingsForOsType:kCCBPublisherOSTypeAndroid];
    osSettingsAndroid.audio_quality = 2;
    osSettingsAndroid.resolutions.resolution_1x = NO;
    osSettingsAndroid.resolutions.resolution_2x = YES;
    osSettingsAndroid.resolutions.resolution_4x = YES;

    [_packageSettings setOSSettings:osSettingsAndroid forOsType:kCCBPublisherOSTypeAndroid];

    [_packageSettings store];

    [self assertFileExists:@"foo/project.spritebuilder/Packages/mypackage.sbpack/Package.plist"];


    PackageSettings *settingsLoaded = [[PackageSettings alloc] initWithPackage:_package];
    [settingsLoaded loadWithError:nil];

    XCTAssertEqual(_packageSettings.publishToMainProject, settingsLoaded.publishToMainProject);
    XCTAssertEqualObjects(_packageSettings.customOutputDirectory, settingsLoaded.customOutputDirectory);
    XCTAssertEqual(_packageSettings.publishEnvironment, settingsLoaded.publishEnvironment);
    XCTAssertEqual(_packageSettings.publishToZip, settingsLoaded.publishToZip);
    XCTAssertEqual(_packageSettings.publishToCustomOutputDirectory, settingsLoaded.publishToCustomOutputDirectory);
    XCTAssertEqual(_packageSettings.resourceAutoScaleFactor, settingsLoaded.resourceAutoScaleFactor);

    XCTAssertTrue(_packageSettings.mainProjectResolutions.resolution_1x);
    XCTAssertTrue(_packageSettings.mainProjectResolutions.resolution_2x);
    XCTAssertFalse(_packageSettings.mainProjectResolutions.resolution_4x);

    PublishOSSettings *osSettingsAndroidLoaded = [settingsLoaded settingsForOsType:kCCBPublisherOSTypeAndroid];
    XCTAssertEqual(osSettingsAndroidLoaded.audio_quality, osSettingsAndroid.audio_quality);
    XCTAssertTrue(osSettingsAndroidLoaded.resolutions.resolution_4x);
    XCTAssertFalse(osSettingsAndroidLoaded.resolutions.resolution_1x);

    PublishOSSettings *osSettingsIOSLoaded = [settingsLoaded settingsForOsType:kCCBPublisherOSTypeIOS];
    XCTAssertEqual(osSettingsIOSLoaded.audio_quality, osSettingsIOS.audio_quality);
    XCTAssertTrue(osSettingsIOSLoaded.resolutions.resolution_1x);
    XCTAssertFalse(osSettingsIOSLoaded.resolutions.resolution_4x);
}

- (void)testLoadingEmptyAndNonExistentPackageSettingsFile
{
    NSError *error2;
    XCTAssertFalse([_packageSettings loadWithError:&error2]);

    XCTAssertNotNil(error2);
    XCTAssertEqual(error2.code, SBPackageSettingsEmptyOrDoesNotExist);

    // ----

    NSDictionary *values = @{};
    [values writeToFile:[self fullPathForFile:@"foo/project.spritebuilder/Packages/mypackage.sbpack/Package.plist"] atomically:YES];

    NSError *error;
    XCTAssertFalse([_packageSettings loadWithError:&error]);

    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, SBPackageSettingsEmptyOrDoesNotExist);
}

- (void)testEffectiveOutputDir
{
    _packageSettings.customOutputDirectory = @"foo";
    _packageSettings.publishToCustomOutputDirectory = YES;

    XCTAssertEqualObjects(_packageSettings.effectiveOutputDirectory, @"foo");

    _packageSettings.publishToCustomOutputDirectory = NO;

    XCTAssertEqualObjects(_packageSettings.effectiveOutputDirectory, DEFAULT_OUTPUTDIR_PUBLISHED_PACKAGES);

    _packageSettings.customOutputDirectory = nil;
    _packageSettings.publishToCustomOutputDirectory = YES;
    XCTAssertEqualObjects(_packageSettings.effectiveOutputDirectory, DEFAULT_OUTPUTDIR_PUBLISHED_PACKAGES);

    _packageSettings.customOutputDirectory = @"    ";
    _packageSettings.publishToCustomOutputDirectory = YES;
    XCTAssertEqualObjects(_packageSettings.effectiveOutputDirectory, DEFAULT_OUTPUTDIR_PUBLISHED_PACKAGES);
}

- (void)testFullPath
{
    XCTAssertEqualObjects(_packageSettings.fullPath, [self fullPathForFile:@"foo/project.spritebuilder/Packages/mypackage.sbpack/Package.plist"]);
}

@end
