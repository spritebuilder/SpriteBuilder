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
#import "SceneGraph.h"
#import "CCBDocumentDataCreator.h"
#import "CCBDocument.h"
#import "PlugInManager.h"
#import "CCBPublishingTarget.h"
#import "ProjectSettings+Convenience.h"
#import "ResourcePropertyKeys.h"
#import "MiscConstants.h"
#import "RMPackage.h"
#import "SBPackageSettings.h"
#import "CCBPublisherCacheCleaner.h"
#import "NSNumber+ImageResolutions.h"

@interface CCBPublisher_Tests : FileSystemTestCase

@property (nonatomic, strong) ProjectSettings *projectSettings;
@property (nonatomic, strong) CCBWarnings *warnings;
@property (nonatomic, strong) CCBPublisher *publisher;
@property (nonatomic, strong) CCBPublishingTarget *targetIOS;
@property (nonatomic, strong) CCBPublishingTarget *targetAndroid;

@end


@implementation CCBPublisher_Tests

- (void)setUp
{
    [super setUp];

    self.projectSettings = [[ProjectSettings alloc] init];
    _projectSettings.projectPath = [self fullPathForFile:@"baa.spritebuilder/publishtest.ccbproj"];
    _projectSettings.publishEnabledIOS = YES;
    _projectSettings.publishEnabledAndroid = NO;

    RMPackage *package = [[RMPackage alloc] init];
    package.dirPath = [self fullPathForFile:@"baa.spritebuilder/Packages/foo.sbpack"];
    [_projectSettings addResourcePath:package.dirPath error:nil];

    [CCBPublisherCacheCleaner cleanWithProjectSettings:_projectSettings];

    SBPackageSettings *packageSettings = [[SBPackageSettings alloc] initWithPackage:package];

    self.warnings = [[CCBWarnings alloc] init];
    self.publisher = [[CCBPublisher alloc] initWithProjectSettings:_projectSettings
                                                   packageSettings:@[packageSettings]
                                                          warnings:_warnings
                                                     finishedBlock:nil];

    self.targetIOS = [[CCBPublishingTarget alloc] init];
    _targetIOS.osType = kCCBPublisherOSTypeIOS;
    _targetIOS.inputPackages = @[packageSettings];
    _targetIOS.outputDirectory = [self fullPathForFile:@"Published-iOS"];
    _targetIOS.resolutions = @[@(1), @(2), @(4)];

    self.targetAndroid = [[CCBPublishingTarget alloc] init];
    _targetAndroid.osType = kCCBPublisherOSTypeAndroid;
    _targetAndroid.inputPackages = @[packageSettings];
    _targetAndroid.outputDirectory = [self fullPathForFile:@"Published-Android"];
    _targetAndroid.resolutions = @[@(1), @(2), @(4)];

    [self createFolders:@[@"Published-iOS", @"Published-Android", @"baa.spritebuilder/Packages/foo.sbpack"]];
}

- (void)testPublishingProject
{
    // Language files are just copied
    [self createEmptyFiles:@[@"baa.spritebuilder/Packages/foo.sbpack/Strings.ccbLang"]];
    [self createEmptyFiles:@[@"baa.spritebuilder/Packages/foo.sbpack/Package.plist"]];

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

    [_publisher addPublishingTarget:_targetIOS];
    [_publisher start];

    [self assertFileExists:@"Published-iOS/Strings.ccbLang"];

    for (NSNumber *resolution in @[@(1), @(2), @(4)])
    {
        [self assertFilesExistRelativeToDirectory:@"Published-iOS" filesPaths:@[
                [NSString stringWithFormat:@"ccbResources/ccbButtonHighlighted%@.png", [resolution resolutionTag]],
                [NSString stringWithFormat:@"ccbResources/ccbButtonHighlighted2%@.png", [resolution resolutionTag]],
                [NSString stringWithFormat:@"photoshop%@.png", [resolution resolutionTag]]
        ]];
    }

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

    [self assertPNGAtPath:@"Published-iOS/ccbResources/ccbButtonHighlighted-1x.png" hasWidth:1 hasHeight:3];
    [self assertPNGAtPath:@"Published-iOS/ccbResources/ccbButtonHighlighted2-1x.png" hasWidth:5 hasHeight:2];
    [self assertPNGAtPath:@"Published-iOS/ccbResources/ccbButtonHighlighted-2x.png" hasWidth:2 hasHeight:6];
    [self assertPNGAtPath:@"Published-iOS/ccbResources/ccbButtonHighlighted2-2x.png" hasWidth:10 hasHeight:4];
    [self assertPNGAtPath:@"Published-iOS/ccbResources/ccbButtonHighlighted-4x.png" hasWidth:4 hasHeight:12];
    [self assertPNGAtPath:@"Published-iOS/ccbResources/ccbButtonHighlighted2-4x.png" hasWidth:20 hasHeight:8];

    [self assertFileDoesNotExist:@"Published-iOS/Package.plist"];
}

- (void)testPublishBMFont
{
    [self createEmptyFilesRelativeToDirectory:@"baa.spritebuilder/Packages/foo.sbpack/test.bmfont" files:@[
            @"resources-phone/din.fnt",
            @"resources-phone/din.png",
            @"resources-phonehd/din.fnt",
            @"resources-phonehd/din.png",
            @"resources-tablet/din.fnt",
            @"resources-tablet/din.png",
            @"resources-tablethd/din.fnt",
            @"resources-tablethd/din.png",
    ]];

    [_publisher addPublishingTarget:_targetIOS];
    [_publisher start];

    [self assertFilesExistRelativeToDirectory:@"Published-iOS/test.bmfont" filesPaths:@[
            @"resources-phone/din.fnt",
            @"resources-phone/din.png",
            @"resources-phonehd/din.fnt",
            @"resources-phonehd/din.png",
            @"resources-tablet/din.fnt",
            @"resources-tablet/din.png",
            @"resources-tablethd/din.fnt",
            @"resources-tablethd/din.png",
    ]];
}

- (void)testPublishCCBs
{
    SceneGraph *sceneGraph = [[SceneGraph alloc] initWithProjectSettings:_projectSettings];
    CCNode *root = [[PlugInManager sharedManager] createDefaultNodeOfType:@"CCNode"];
    sceneGraph.rootNode = root;

    CCBDocument *document = [[CCBDocument alloc] init];
    CCBDocumentDataCreator *documentCreator = [[CCBDocumentDataCreator alloc] initWithSceneGraph:sceneGraph
                                                                                document:document
                                                                         projectSettings:_projectSettings
                                                                              sequenceId:0];

    NSMutableDictionary *doc = [documentCreator createData];
    [doc writeToFile:[self fullPathForFile:@"baa.spritebuilder/Packages/foo.sbpack/mainScene.ccb"] atomically:YES];

    [_publisher addPublishingTarget:_targetIOS];
    [_publisher start];

    [self assertFileExists:@"Published-iOS/mainScene.ccbi"];
}

- (void)testCustomScalingFactorsForImages
{
    [self createPNGAtPath:@"baa.spritebuilder/Packages/foo.sbpack/resources-auto/rocket.png" width:4 height:20];

    // Overriden resolution for tablet hd
    [self createPNGAtPath:@"baa.spritebuilder/Packages/foo.sbpack/resources-4x/rocket.png" width:3 height:17];

    [_projectSettings setProperty:@1 forRelPath:@"rocket.png" andKey:RESOURCE_PROPERTY_IMAGE_SCALE_FROM];
    [_projectSettings setProperty:@YES forRelPath:@"rocket.png" andKey:RESOURCE_PROPERTY_IMAGE_USEUISCALE];

    [_publisher addPublishingTarget:_targetIOS];
    [_publisher start];

    // The overridden case
    [self assertPNGAtPath:@"Published-iOS/rocket-4x.png" hasWidth:3 hasHeight:17];

    [self assertPNGAtPath:@"Published-iOS/rocket-1x.png" hasWidth:4 hasHeight:20];
    [self assertPNGAtPath:@"Published-iOS/rocket-2x.png" hasWidth:8 hasHeight:40];
}

- (void)testDifferentOutputFormatsForIOSAndAndroid
{
    [self createPNGAtPath:@"baa.spritebuilder/Packages/foo.sbpack/resources-auto/rocket.png" width:4 height:20];
    [self copyTestingResource:@"blank.wav" toFolder:@"baa.spritebuilder/Packages/foo.sbpack"];

    _projectSettings.publishEnabledAndroid = YES;

    [_projectSettings setProperty:@(kFCImageFormatJPG_High) forRelPath:@"rocket.png" andKey:RESOURCE_PROPERTY_IOS_IMAGE_FORMAT];
    [_projectSettings setProperty:@(kFCImageFormatJPG_High) forRelPath:@"rocket.png" andKey:RESOURCE_PROPERTY_ANDROID_IMAGE_FORMAT];
    [_projectSettings setProperty:@(kFCSoundFormatMP4) forRelPath:@"blank.wav" andKey:RESOURCE_PROPERTY_IOS_SOUND];

    [_publisher addPublishingTarget:_targetIOS];
    [_publisher addPublishingTarget:_targetAndroid];
    [_publisher start];

    [self assertRenamingRuleInfFileLookup:@"Published-iOS/fileLookup.plist" originalName:@"rocket.png" renamedName:@"rocket.jpg"];
    [self assertRenamingRuleInfFileLookup:@"Published-iOS/fileLookup.plist" originalName:@"blank.wav" renamedName:@"blank.m4a"];

    [self assertRenamingRuleInfFileLookup:@"Published-Android/fileLookup.plist" originalName:@"rocket.png" renamedName:@"rocket.jpg"];
    [self assertRenamingRuleInfFileLookup:@"Published-Android/fileLookup.plist" originalName:@"blank.wav" renamedName:@"blank.ogg"];

    [self assertJPGAtPath:@"Published-iOS/rocket-1x.jpg" hasWidth:1 hasHeight:5];
    [self assertJPGAtPath:@"Published-iOS/rocket-2x.jpg" hasWidth:2 hasHeight:10];
    [self assertJPGAtPath:@"Published-iOS/rocket-4x.jpg" hasWidth:4 hasHeight:20];

    [self assertJPGAtPath:@"Published-Android/rocket-1x.jpg" hasWidth:1 hasHeight:5];
    [self assertJPGAtPath:@"Published-Android/rocket-2x.jpg" hasWidth:2 hasHeight:10];
    [self assertJPGAtPath:@"Published-Android/rocket-4x.jpg" hasWidth:4 hasHeight:20];

    [self assertFileExists:@"Published-iOS/blank.m4a"];
    [self assertFileExists:@"Published-Android/blank.ogg"];

    NSData *wavData = [[NSFileManager defaultManager] contentsAtPath:[self fullPathForFile:@"baa.spritebuilder/Packages/foo.sbpack/blank.wav"]];
    NSData *m4aData = [[NSFileManager defaultManager] contentsAtPath:[self fullPathForFile:@"Published-iOS/blank.m4a"]];
    NSData *oggData = [[NSFileManager defaultManager] contentsAtPath:[self fullPathForFile:@"Published-Android/blank.ogg"]];
    XCTAssertNotNil(wavData, @"wav data must not be nil");
    XCTAssertNotNil(m4aData, @"m4a data must not be nil");
    XCTAssertNotNil(oggData, @"ogg data must not be nil");
    XCTAssertTrue(![m4aData isEqualToData:wavData], @"m4a data must be different than wav data");
    XCTAssertTrue(![oggData isEqualToData:wavData], @"ogg data must be different than wav data");
}

- (void)testSpriteSheets
{
    [self createPNGAtPath:@"baa.spritebuilder/Packages/foo.sbpack/sheet/resources-auto/rock.png" width:4 height:4 color:[NSColor redColor]];
    [self createPNGAtPath:@"baa.spritebuilder/Packages/foo.sbpack/sheet/resources-auto/scissor.png" width:8 height:4 color:[NSColor greenColor]];
    [self createPNGAtPath:@"baa.spritebuilder/Packages/foo.sbpack/sheet/resources-auto/paper.png" width:12 height:12 color:[NSColor whiteColor]];
    [self createPNGAtPath:@"baa.spritebuilder/Packages/foo.sbpack/sheet/resources-auto/shotgun.png" width:4 height:12 color:[NSColor blackColor]];
    [self createPNGAtPath:@"baa.spritebuilder/Packages/foo.sbpack/sheet/resources-auto/sword.png" width:4 height:12 color:[NSColor yellowColor]];

    [_projectSettings setProperty:@(YES) forRelPath:@"sheet" andKey:RESOURCE_PROPERTY_IS_SMARTSHEET];

    [_publisher addPublishingTarget:_targetIOS];
    [_publisher start];

    // The resolutions tests may be a bit too much here, but there are no
    // Tupac tests at the moment
    [self assertFileExists:@"Published-iOS/sheet-2x.plist"];
    [self assertPNGAtPath:@"Published-iOS/sheet-2x.png" hasWidth:32 hasHeight:16];
    [self assertFileExists:@"Published-iOS/sheet-4x.plist"];
    [self assertPNGAtPath:@"Published-iOS/sheet-4x.png" hasWidth:32 hasHeight:32];
    [self assertFileExists:@"Published-iOS/sheet-1x.plist"];
    [self assertPNGAtPath:@"Published-iOS/sheet-1x.png" hasWidth:16 hasHeight:8];

    // Previews are generated in texture packer
    [self assertFileExists:@"baa.spritebuilder/Packages/foo.sbpack/sheet.ppng"];

    [self assertFileExists:@"Published-iOS/spriteFrameFileList.plist"];
    [self assertSpriteFrameFileList:@"Published-iOS/spriteFrameFileList.plist" containsEntry:@"sheet-1x.plist"];
    [self assertSpriteFrameFileList:@"Published-iOS/spriteFrameFileList.plist" containsEntry:@"sheet-2x.plist"];
    [self assertSpriteFrameFileList:@"Published-iOS/spriteFrameFileList.plist" containsEntry:@"sheet-4x.plist"];
}

- (void)testSpriteSheetsFileLookup
{
    [self copyTestingResource:@"photoshop.psd" toRelPath:@"baa.spritebuilder/Packages/foo.sbpack/sub1/sheet1/resources-auto/rock.psd"];
    [self copyTestingResource:@"photoshop.psd" toRelPath:@"baa.spritebuilder/Packages/foo.sbpack/sub2/sheet2/resources-auto/scissors.psd"];

    [_projectSettings setProperty:@(YES) forRelPath:@"sub1/sheet1" andKey:RESOURCE_PROPERTY_IS_SMARTSHEET];
    [_projectSettings setProperty:@(YES) forRelPath:@"sub2/sheet2" andKey:RESOURCE_PROPERTY_IS_SMARTSHEET];

    _targetIOS.resolutions = @[@(1)];
    [_publisher addPublishingTarget:_targetIOS];
    [_publisher start];

    void (^test)() = ^void()
    {
        [self assertFileExists:@"Published-iOS/sub1/sheet1-1x.plist"];
        [self assertFileExists:@"Published-iOS/sub1/sheet1-1x.png"];
        [self assertFileExists:@"Published-iOS/sub2/sheet2-1x.plist"];
        [self assertFileExists:@"Published-iOS/sub2/sheet2-1x.png"];
        [self assertFileExists:@"Published-iOS/fileLookup.plist"];

        // Testcase after bugfix which placed the intermediateFileLookup.plist in the project's path instead of the caches dir
        [self assertFileDoesNotExist:@"baa.spritebuilder/Packages/foo.sbpack/sub1/sheet1/intermediateFileLookup.plist"];
        [self assertFileDoesNotExist:@"baa.spritebuilder/Packages/foo.sbpack/sub2/sheet2/intermediateFileLookup.plist"];

        [self assertRenamingRuleInfFileLookup:@"Published-iOS/fileLookup.plist" originalName:@"sub1/sheet1/rock.psd" renamedName:@"sub1/sheet1/rock.png"];
        [self assertRenamingRuleInfFileLookup:@"Published-iOS/fileLookup.plist" originalName:@"sub2/sheet2/scissors.psd" renamedName:@"sub2/sheet2/scissors.png"];
    };

    test();

    // Publish again to see if the solution works with cached files
    [_publisher start];

    test();
}

- (void)testSpriteSheetOutputPVRRGBA88888AndPVRTC
{
    [self createPNGAtPath:@"baa.spritebuilder/Packages/foo.sbpack/pvr/resources-auto/rock.png" width:4 height:4 color:[NSColor redColor]];
    [self createPNGAtPath:@"baa.spritebuilder/Packages/foo.sbpack/pvr/resources-auto/scissor.png" width:8 height:4 color:[NSColor greenColor]];

    [self createPNGAtPath:@"baa.spritebuilder/Packages/foo.sbpack/pvrtc/resources-auto/rock.png" width:4 height:4 color:[NSColor redColor]];
    [self createPNGAtPath:@"baa.spritebuilder/Packages/foo.sbpack/pvrtc/resources-auto/scissor.png" width:8 height:4 color:[NSColor greenColor]];

    [_projectSettings setProperty:@(YES) forRelPath:@"pvr" andKey:RESOURCE_PROPERTY_IS_SMARTSHEET];
    [_projectSettings setProperty:@(kFCImageFormatPVR_RGBA8888) forRelPath:@"pvr" andKey:RESOURCE_PROPERTY_IOS_IMAGE_FORMAT];

    [_projectSettings setProperty:@(YES) forRelPath:@"pvrtc" andKey:RESOURCE_PROPERTY_IS_SMARTSHEET];
    [_projectSettings setProperty:@(kFCImageFormatPVRTC_4BPP) forRelPath:@"pvrtc" andKey:RESOURCE_PROPERTY_IOS_IMAGE_FORMAT];

    _targetIOS.resolutions = @[@(2)];
    [_publisher addPublishingTarget:_targetIOS];
    [_publisher start];

    [self assertFileExists:@"Published-iOS/pvr-2x.plist"];
    [self assertFileExists:@"Published-iOS/pvr-2x.pvr"];
    // Previews are generated in texture packer
    [self assertFileExists:@"baa.spritebuilder/Packages/foo.sbpack/pvr.ppng"];

    [self assertFileExists:@"Published-iOS/pvrtc-2x.plist"];
    [self assertFileExists:@"Published-iOS/pvrtc-2x.pvr"];
    [self assertFileExists:@"baa.spritebuilder/Packages/foo.sbpack/pvrtc.ppng"];

    [self assertFileExists:@"Published-iOS/spriteFrameFileList.plist"];
    [self assertSpriteFrameFileList:@"Published-iOS/spriteFrameFileList.plist" containsEntry:@"pvr-2x.plist"];
    [self assertSpriteFrameFileList:@"Published-iOS/spriteFrameFileList.plist" containsEntry:@"pvrtc-2x.plist"];
}

- (void)testRepublishingWithoutCleaningCache
{
    [self createPNGAtPath:@"baa.spritebuilder/Packages/foo.sbpack/sheet/resources-auto/rock.png" width:4 height:4 color:[NSColor redColor]];
    [_projectSettings setProperty:@(YES) forRelPath:@"sheet" andKey:RESOURCE_PROPERTY_IS_SMARTSHEET];
    _targetIOS.resolutions = @[@(2)];

    [_publisher addPublishingTarget:_targetIOS];
    // Yes that's correct, publishing twice
    [_publisher start];
    [_publisher start];

    [self assertFilesExistRelativeToDirectory:@"Published-iOS" filesPaths:@[
            @"sheet-2x.plist",
            @"sheet-2x.png"
    ]];

    [self assertFileExists:@"baa.spritebuilder/Packages/foo.sbpack/sheet.ppng"];
    [self assertFileExists:@"Published-iOS/spriteFrameFileList.plist"];
    [self assertSpriteFrameFileList:@"Published-iOS/spriteFrameFileList.plist" containsEntry:@"sheet-2x.plist"];
}

- (void)testGreyscaleImagePublishing
{
    [self createFolders:@[@"baa.spritebuilder/Packages/foo.sbpack/images/resources-auto"]];
    [self copyTestingResource:@"greyscale.png" toFolder:@"baa.spritebuilder/Packages/foo.sbpack/images/resources-auto"];

    _projectSettings.designTarget = kCCBDesignTargetFixed;
    _projectSettings.defaultOrientation = kCCBOrientationPortrait;

    [_publisher addPublishingTarget:_targetIOS];
    [_publisher start];

    [self assertFileExists:@"Published-iOS/images/greyscale-1x.png"];
    [self assertFileExists:@"Published-iOS/images/greyscale-2x.png"];
    [self assertFileExists:@"Published-iOS/images/greyscale-4x.png"];
}

- (void)testEnums
{
    XCTAssertEqual(kCCBPublisherOSTypeHTML5, 0, @"Enum value kCCBPublisherOSTypeHTML5  must not change");
    XCTAssertEqual(kCCBPublisherOSTypeIOS, 1, @"Enum value kCCBPublisherOSTypeIOS  must not change");
    XCTAssertEqual(kCCBPublisherOSTypeAndroid, 2, @"Enum value kCCBPublisherOSTypeAndroid  must not change");

    XCTAssertEqual(kCCBPublishEnvironmentDevelop, 0, @"Enum value kCCBPublishEnvironmentDevelop  must not change");
    XCTAssertEqual(kCCBPublishEnvironmentRelease, 1, @"Enum value kCCBPublishEnvironmentRelease  must not change");

    XCTAssertEqual(kCCBPublishFormatSound_ios_caf, 0, @"Enum value kCCBPublishFormatSound_ios_caf  must not change");
    XCTAssertEqual(kCCBPublishFormatSound_ios_mp4, 1, @"Enum value kCCBPublishFormatSound_ios_mp4  must not change");

    XCTAssertEqual(kCCBPublishFormatSound_android_ogg, 0, @"Enum value kCCBPublishFormatSound_android_ogg  must not change");
}

#pragma mark - assert helpers

- (void)assertSpriteFrameFileList:(NSString *)filename containsEntry:(NSString *)entry
{
    NSString *fullFilePath = [self fullPathForFile:filename];
    NSDictionary *completeFile = [NSDictionary dictionaryWithContentsOfFile:[self fullPathForFile:filename]];
    NSArray *files = completeFile[@"spriteFrameFiles"];

    XCTAssertTrue([files containsObject:entry], @"SpriteFrameFileList does not contain entry \"%@\", entries found %@ at path \"%@\"", entry, files, fullFilePath);
}

- (void)assertRenamingRuleInfFileLookup:(NSString *)fileLookupName originalName:(NSString *)originalName renamedName:(NSString *)expectedRenamedName
{
    NSString *fullFilePath = [self fullPathForFile:fileLookupName];
    NSDictionary *fileLookup = [NSDictionary dictionaryWithContentsOfFile:fullFilePath];
    NSDictionary *rules = fileLookup[@"filenames"];

    XCTAssertTrue([expectedRenamedName isEqualToString:rules[originalName]], @"Rename rule does not match, found \"%@\" for key \"%@\" expected: \"%@\" at path \"%@\"",
                  rules[originalName], originalName, expectedRenamedName, fullFilePath );
}

- (void)assertConfigCocos2d:(NSString *)fileName isEqualToDictionary:(NSDictionary *)expectedDict;
{
    NSString *fullFilePath = [self fullPathForFile:fileName];

    NSDictionary *config = [NSDictionary dictionaryWithContentsOfFile:fullFilePath];

    XCTAssertNotNil(config, @"Config is nil for given filename \"%@\"", [self fullPathForFile:fileName]);
    XCTAssertTrue([config isEqualToDictionary:expectedDict], @"Dictionary %@ does not match %@ at path \"%@\"", config, expectedDict, fullFilePath);
}

@end
