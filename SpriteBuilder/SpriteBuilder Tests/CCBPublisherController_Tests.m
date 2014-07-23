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
    _packageSettings.outputDirectory = @"../Published-Packages";

    PublishOSSettings *iosSettings = [_packageSettings settingsForOsType:kCCBPublisherOSTypeIOS];
    iosSettings.resolution_tablethd = YES;
    iosSettings.resolution_phone = YES;
    iosSettings.enabled = YES;

    PublishOSSettings *androidSettings = [_packageSettings settingsForOsType:kCCBPublisherOSTypeAndroid];
    androidSettings.resolution_tablet = YES;
    androidSettings.resolution_phonehd = YES;
    androidSettings.enabled = YES;

    [self createFolders:@[@"Published-Packages", @"baa.spritebuilder/Packages/foo.sbpack"]];

    self.publisherController = [[CCBPublisherController alloc] init];
    _publisherController.projectSettings = _projectSettings;
    _publisherController.packageSettings = @[_packageSettings];
    _publisherController.publishMainProject = NO;
}

- (void)testPackageExport
{
    [self createPNGAtPath:@"baa.spritebuilder/Packages/foo.sbpack/resources-auto/plane.png" width:10 height:2];

    [_publisherController startAsync:NO];

    [self assertFilesExistRelativeToDirectory:@"Published-Packages/foo-iOS-tablethd" filesPaths:@[
            @"resources-tablethd/plane.png",
            @"configCocos2d.plist",
            @"fileLookup.plist",
            @"spriteFrameFileList.plist"
    ]];

    [self assertFilesExistRelativeToDirectory:@"Published-Packages/foo-iOS-phone" filesPaths:@[
            @"resources-phone/plane.png",
            @"configCocos2d.plist",
            @"fileLookup.plist",
            @"spriteFrameFileList.plist"
    ]];

    [self assertFilesExistRelativeToDirectory:@"Published-Packages/foo-Android-tablet" filesPaths:@[
            @"resources-tablet/plane.png",
            @"configCocos2d.plist",
            @"fileLookup.plist",
            @"spriteFrameFileList.plist"
    ]];

    [self assertFilesExistRelativeToDirectory:@"Published-Packages/foo-Android-phonehd" filesPaths:@[
            @"resources-phonehd/plane.png",
            @"configCocos2d.plist",
            @"fileLookup.plist",
            @"spriteFrameFileList.plist"
    ]];

    [self assertFilesExistRelativeToDirectory:@"Published-Packages" filesPaths:@[
            @"foo-iOS-tablethd.zip",
            @"foo-iOS-phone.zip",
            @"foo-Android-tablet.zip",
            @"foo-Android-phonehd.zip"
    ]];
}

@end
