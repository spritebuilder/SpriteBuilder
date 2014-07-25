//
//  CCBPublisherController_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 21.07.14.
//
//

#import <XCTest/XCTest.h>
#import "FileSystemTestCase.h"
#import "CCBPublisherController.h"
#import "PackagePublishSettings.h"
#import "ProjectSettings.h"
#import "RMPackage.h"
#import "FileSystemTestCase+Images.h"
#import "PublishOSSettings.h"
#import "MiscConstants.h"

@interface CCBPublisherController_Tests : FileSystemTestCase

@property (nonatomic, strong) CCBPublisherController *publisherController;
@property (nonatomic, strong) ProjectSettings *projectSettings;
@property (nonatomic, strong) PackagePublishSettings *packageSettings;
@property (nonatomic, strong) RMPackage *package;

@end


@implementation CCBPublisherController_Tests

- (void)setUp
{
    [super setUp];

    self.projectSettings = [[ProjectSettings alloc] init];
    _projectSettings.projectPath = [self fullPathForFile:@"baa.spritebuilder/publishtest.ccbproj"];
    [_projectSettings addResourcePath:[self fullPathForFile:@"baa.spritebuilder/Packages/foo.sbpack"] error:nil];

    self.package = [[RMPackage alloc] init];
    _package.dirPath = [self fullPathForFile:@"baa.spritebuilder/Packages/foo.sbpack"];

    self.packageSettings = [[PackagePublishSettings alloc] initWithPackage:_package];
    _packageSettings.publishToCustomOutputDirectory = NO;

    // _packageSettings.customOutputDirectory = @"../Published-Packages";

    PublishOSSettings *iosSettings = [_packageSettings settingsForOsType:kCCBPublisherOSTypeIOS];
    iosSettings.resolution_tablethd = YES;
    iosSettings.resolution_phone = YES;

    PublishOSSettings *androidSettings = [_packageSettings settingsForOsType:kCCBPublisherOSTypeAndroid];
    androidSettings.resolution_tablet = YES;
    androidSettings.resolution_phonehd = YES;

    [self createFolders:@[@"Published-Packages", @"baa.spritebuilder/Packages/foo.sbpack"]];

    self.publisherController = [[CCBPublisherController alloc] init];
    _publisherController.projectSettings = _projectSettings;
    _publisherController.packageSettings = @[_packageSettings];
    _publisherController.publishMainProject = NO;
}

- (void)testPackageExportToDefaultDirectory
{
    [self createPNGAtPath:@"baa.spritebuilder/Packages/foo.sbpack/resources-auto/plane.png" width:10 height:2];

    [_publisherController startAsync:NO];

    [self assertFileDoesNotExist:@"Published-Packages/foo-iOS-tablethd"];
    [self assertFileDoesNotExist:@"Published-Packages/foo-iOS-phone"];
    [self assertFileDoesNotExist:@"Published-Packages/foo-Android-tablet"];
    [self assertFileDoesNotExist:@"Published-Packages/foo-Android-phonehd"];

    [self assertFilesExistRelativeToDirectory:[@"baa.spritebuilder" stringByAppendingPathComponent:DEFAULT_OUTPUTDIR_PUBLISHED_PACKAGES] filesPaths:@[
            @"foo-iOS-tablethd.zip",
            @"foo-iOS-phone.zip",
            @"foo-Android-tablet.zip",
            @"foo-Android-phonehd.zip"
    ]];
}

- (void)testPackageExportToCustomDirectory
{
    [self createPNGAtPath:@"baa.spritebuilder/Packages/foo.sbpack/resources-auto/plane.png" width:10 height:2];

    _packageSettings.publishToCustomOutputDirectory = YES;
    _packageSettings.customOutputDirectory = @"../custom";

    PublishOSSettings *iosSettings = [_packageSettings settingsForOsType:kCCBPublisherOSTypeIOS];
    iosSettings.resolutions = @[];

    PublishOSSettings *androidSettings = [_packageSettings settingsForOsType:kCCBPublisherOSTypeAndroid];
    androidSettings.resolutions = @[];
    androidSettings.resolution_phone = YES;

    [_publisherController startAsync:NO];

    [self assertFilesExistRelativeToDirectory:@"custom" filesPaths:@[
          @"foo-Android-phone.zip"
    ]];
}

@end
