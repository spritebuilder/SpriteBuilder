//
//  CCBPublisher_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 10.07.14.
//
//

#import <XCTest/XCTest.h>
#import "FileSystemTestCase.h"
#import "FileSystemTestCase+Images.h"
#import "CCBPublisher.h"
#import "ProjectSettings.h"
#import "CCBWarnings.h"
#import "FCFormatConverter.h"

@interface CCBPublisher_Tests : FileSystemTestCase

@property (nonatomic, strong) ProjectSettings *projectSettings;
@property (nonatomic, strong) CCBWarnings *warnings;
@property (nonatomic, strong) CCBPublisher *publisher;

@end

@implementation CCBPublisher_Tests

- (void)setUp
{
    [super setUp];

    self.projectSettings = [[ProjectSettings alloc] init];
    _projectSettings.projectPath = [self fullPathForFile:@"baa.spritebuilder/publishtest.ccbproj"];
    _projectSettings.publishEnablediPhone = YES;
    _projectSettings.publishEnabledAndroid = NO;

    [_projectSettings addResourcePath:[self fullPathForFile:@"baa.spritebuilder/Packages/foo.sbpack"] error:nil];

    self.warnings = [[CCBWarnings alloc] init];

    self.publisher = [[CCBPublisher alloc] initWithProjectSettings:_projectSettings
                                                          warnings:_warnings
                                                     finishedBlock:nil];

    _publisher.publishInputDirectories = @[[self fullPathForFile:@"baa.spritebuilder/Packages/foo.sbpack"]];
    [_publisher setPublishOutputDirectory:[self fullPathForFile:@"Published-iOS"] forTargetType:kCCBPublisherTargetTypeIPhone];
    [_publisher setPublishOutputDirectory:[self fullPathForFile:@"Published-Android"] forTargetType:kCCBPublisherTargetTypeAndroid];

    [self createFolders:@[@"Published-iOS", @"Published-Android"]];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testPublishingProject
{
    [self createPNGAtPath:@"baa.spritebuilder/Packages/foo.sbpack/ccbResources/resources-auto/ccbButtonHighlighted.png"
                    width:4
                   height:12];
    [self createPNGAtPath:@"baa.spritebuilder/Packages/foo.sbpack/ccbResources/resources-auto/ccbButtonHighlighted2.png"
                    width:20
                   height:8];

    [self copyTestingResource:@"blank.wav" toFolder:@"baa.spritebuilder/Packages/foo.sbpack"];
    [self copyTestingResource:@"photoshop.psd" toFolder:@"baa.spritebuilder/Packages/foo.sbpack/resources-auto"];

    _projectSettings.designTarget = kCCBDesignTargetFixed;
    _projectSettings.defaultOrientation = kCCBOrientationPortrait;
    _projectSettings.resourceAutoScaleFactor = 4;

    [_publisher start];

    [self assertFileExists:@"Published-iOS/ccbResources/resources-tablet/ccbButtonHighlighted.png"];
    [self assertFileExists:@"Published-iOS/ccbResources/resources-tablet/ccbButtonHighlighted2.png"];
    [self assertFileExists:@"Published-iOS/ccbResources/resources-tablethd/ccbButtonHighlighted.png"];
    [self assertFileExists:@"Published-iOS/ccbResources/resources-tablethd/ccbButtonHighlighted2.png"];
    [self assertFileExists:@"Published-iOS/ccbResources/resources-phone/ccbButtonHighlighted.png"];
    [self assertFileExists:@"Published-iOS/ccbResources/resources-phone/ccbButtonHighlighted2.png"];
    [self assertFileExists:@"Published-iOS/ccbResources/resources-phonehd/ccbButtonHighlighted.png"];
    [self assertFileExists:@"Published-iOS/ccbResources/resources-phonehd/ccbButtonHighlighted2.png"];
    [self assertFileExists:@"Published-iOS/resources-tablet/photoshop.png"];
    [self assertFileExists:@"Published-iOS/resources-tablethd/photoshop.png"];
    [self assertFileExists:@"Published-iOS/resources-phone/photoshop.png"];
    [self assertFileExists:@"Published-iOS/resources-phonehd/photoshop.png"];

    [self assertFileExists:@"Published-iOS/blank.caf"];
    [self assertFileExists:@"Published-iOS/configCocos2d.plist"];
    [self assertFileExists:@"Published-iOS/fileLookup.plist"];
    [self assertFileExists:@"Published-iOS/spriteFrameFileList.plist"];

    [self assertConfigCocos2d:@"Published-iOS/configCocos2d.plist" isEqualToDictionary:
            @{
                @"CCSetupScreenMode": @"CCScreenModeFixed",
                @"CCSetupScreenOrientation": @"CCScreenOrientationPortrait",
                @"CCSetupTabletScale2X": @(YES)
            }];

    [self assertRenamingRuleInfFileLookup:@"Published-iOS/fileLookup.plist" originalName:@"blank.wav" renamedName:@"blank.caf"];
    [self assertRenamingRuleInfFileLookup:@"Published-iOS/fileLookup.plist" originalName:@"photoshop.psd" renamedName:@"photoshop.png"];

    [self assertPNGAtPath:@"Published-iOS/ccbResources/resources-phone/ccbButtonHighlighted.png" hasWidth:1 hasHeight:3];
    [self assertPNGAtPath:@"Published-iOS/ccbResources/resources-phone/ccbButtonHighlighted2.png" hasWidth:5 hasHeight:2];
    [self assertPNGAtPath:@"Published-iOS/ccbResources/resources-phonehd/ccbButtonHighlighted.png" hasWidth:2 hasHeight:6];
    [self assertPNGAtPath:@"Published-iOS/ccbResources/resources-phonehd/ccbButtonHighlighted2.png" hasWidth:10 hasHeight:4];
    [self assertPNGAtPath:@"Published-iOS/ccbResources/resources-tablet/ccbButtonHighlighted.png" hasWidth:2 hasHeight:6];
    [self assertPNGAtPath:@"Published-iOS/ccbResources/resources-tablet/ccbButtonHighlighted2.png" hasWidth:10 hasHeight:4];
    [self assertPNGAtPath:@"Published-iOS/ccbResources/resources-tablethd/ccbButtonHighlighted.png" hasWidth:4 hasHeight:12];
    [self assertPNGAtPath:@"Published-iOS/ccbResources/resources-tablethd/ccbButtonHighlighted2.png" hasWidth:20 hasHeight:8];
}

- (void)testCustomScalingFactorsForImages
{
    [self createPNGAtPath:@"baa.spritebuilder/Packages/foo.sbpack/resources-auto/rocket.png" width:4 height:20];

    // Overriden resolution for tablet hd
    [self createPNGAtPath:@"baa.spritebuilder/Packages/foo.sbpack/resources-tablethd/rocket.png" width:3 height:17];

    _projectSettings.resourceAutoScaleFactor = 4;
    [_projectSettings setValue:[NSNumber numberWithInt:1] forRelPath:@"rocket.png" andKey:@"scaleFrom"];

    [_publisher start];

    // The overridden case
    [self assertPNGAtPath:@"Published-iOS/resources-tablethd/rocket.png" hasWidth:3 hasHeight:17];

    [self assertPNGAtPath:@"Published-iOS/resources-tablet/rocket.png" hasWidth:8 hasHeight:40];
    [self assertPNGAtPath:@"Published-iOS/resources-phone/rocket.png" hasWidth:4 hasHeight:20];
    [self assertPNGAtPath:@"Published-iOS/resources-phonehd/rocket.png" hasWidth:8 hasHeight:40];
}

- (void)testDifferentOutputFormatsForIOSAndAndroid
{
    [self createPNGAtPath:@"baa.spritebuilder/Packages/foo.sbpack/resources-auto/rocket.png" width:4 height:20];
    [self copyTestingResource:@"blank.wav" toFolder:@"baa.spritebuilder/Packages/foo.sbpack"];

    _projectSettings.publishEnabledAndroid = YES;
    _projectSettings.resourceAutoScaleFactor = 4;

    [_projectSettings setValue:[NSNumber numberWithInt:kFCImageFormatJPG_High] forRelPath:@"rocket.png" andKey:@"format_ios"];
    [_projectSettings setValue:[NSNumber numberWithInt:kFCImageFormatJPG_High] forRelPath:@"rocket.png" andKey:@"format_android"];
    [_projectSettings setValue:[NSNumber numberWithInt:kFCSoundFormatMP4] forRelPath:@"blank.wav" andKey:@"format_ios_sound"];

    [_publisher start];

    [self assertRenamingRuleInfFileLookup:@"Published-iOS/fileLookup.plist" originalName:@"rocket.png" renamedName:@"rocket.jpg"];
    [self assertRenamingRuleInfFileLookup:@"Published-iOS/fileLookup.plist" originalName:@"blank.wav" renamedName:@"blank.m4a"];

    [self assertRenamingRuleInfFileLookup:@"Published-Android/fileLookup.plist" originalName:@"rocket.png" renamedName:@"rocket.jpg"];
    [self assertRenamingRuleInfFileLookup:@"Published-Android/fileLookup.plist" originalName:@"blank.wav" renamedName:@"blank.ogg"];

    [self assertJPGAtPath:@"Published-iOS/resources-tablet/rocket.jpg" hasWidth:2 hasHeight:10];
    [self assertJPGAtPath:@"Published-iOS/resources-tablethd/rocket.jpg" hasWidth:4 hasHeight:20];
    [self assertJPGAtPath:@"Published-iOS/resources-phone/rocket.jpg" hasWidth:1 hasHeight:5];
    [self assertJPGAtPath:@"Published-iOS/resources-phonehd/rocket.jpg" hasWidth:2 hasHeight:10];

    [self assertJPGAtPath:@"Published-Android/resources-tablet/rocket.jpg" hasWidth:2 hasHeight:10];
    [self assertJPGAtPath:@"Published-Android/resources-tablethd/rocket.jpg" hasWidth:4 hasHeight:20];
    [self assertJPGAtPath:@"Published-Android/resources-phone/rocket.jpg" hasWidth:1 hasHeight:5];
    [self assertJPGAtPath:@"Published-Android/resources-phonehd/rocket.jpg" hasWidth:2 hasHeight:10];

    [self assertFileExists:@"Published-iOS/blank.m4a"];
    [self assertFileExists:@"Published-Android/blank.ogg"];

/*
    NSLog(@"%@", [self fullPathForFile:@""]);
    NSLog(@"%@", _publisher.publishOutputDirectory);
    NSLog(@"---");
*/
}


#pragma mark - assert helpers

- (void)assertRenamingRuleInfFileLookup:(NSString *)fileLookupName originalName:(NSString *)originalName renamedName:(NSString *)expectedRenamedName
{
    NSDictionary *fileLookup = [NSDictionary dictionaryWithContentsOfFile:[self fullPathForFile:fileLookupName]];
    NSDictionary *rules = fileLookup[@"filenames"];

    XCTAssertTrue([expectedRenamedName isEqualToString:rules[originalName]], @"Rename rule does not match, found \"%@\" for key \"%@\" expected: \"%@\"",
                  rules[originalName], originalName, expectedRenamedName);
}

- (void)assertConfigCocos2d:(NSString *)fileName isEqualToDictionary:(NSDictionary *)expectedDict;
{
    NSDictionary *config = [NSDictionary dictionaryWithContentsOfFile:[self fullPathForFile:fileName]];

    XCTAssertNotNil(config, @"Config is nil for given filename \"%@\"", [self fullPathForFile:fileName]);
    XCTAssertTrue([config isEqualToDictionary:expectedDict], @"Dictionary %@ does not match %@", config, expectedDict);
}

@end
