//
//  ProjectSettings_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 28.05.14.
//
//

#import <XCTest/XCTest.h>

#import "ProjectSettings.h"
#import "SBErrors.h"
#import "ProjectSettings+Packages.h"
#import "NSString+Packages.h"
#import "SBAssserts.h"
#import "MiscConstants.h"
#import "FileSystemTestCase.h"
#import "ProjectSettings+Convenience.h"
#import "RMResource.h"
#import "ResourceManager.h"

@interface ProjectSettings_Tests : FileSystemTestCase

@end


@implementation ProjectSettings_Tests
{
    ProjectSettings *_projectSettings;
}

- (void)setUp
{
    [super setUp];

    _projectSettings = [[ProjectSettings alloc] init];
    _projectSettings.projectPath = @"/project/abc.ccbproj";
}

- (void)testAddResourcePath
{
    NSError *error;
    XCTAssertTrue([_projectSettings addResourcePath:@"/project/resourcepath1" error:&error]);
    XCTAssertNil(error);
    XCTAssertEqual((int)_projectSettings.resourcePaths.count, 1);
}

- (void)testAddResourcePathTwice
{
    NSString *resourcePath = @"/project/resourcepath1";

    NSError *error;
    XCTAssertTrue([_projectSettings addResourcePath:resourcePath error:&error]);
    XCTAssertNil(error);

    NSError *error2;
    XCTAssertFalse([_projectSettings addResourcePath:resourcePath error:&error2]);
    XCTAssertNotNil(error2);
    XCTAssertEqual(error2.code, SBDuplicateResourcePathError);

    XCTAssertEqual((int)_projectSettings.resourcePaths.count, 1);
}

- (void)testIsResourcePathAlreadyInProject
{
    NSString *resourcePath = @"/project/resourcepath1";

    [_projectSettings addResourcePath:resourcePath error:nil];

    XCTAssertTrue([_projectSettings isResourcePathInProject:resourcePath]);

    XCTAssertFalse([_projectSettings isResourcePathInProject:@"/foo/notinproject"]);
}

- (void)testRemoveResourcePath
{
    _projectSettings.projectPath = @"/project/ccbuttonwooga.ccbproj";
    [_projectSettings.resourcePaths addObject:@{@"path" : @"test"}];

    NSError *error;
    XCTAssertTrue([_projectSettings removeResourcePath:@"/project/test" error:&error]);
    XCTAssertEqual((int)_projectSettings.resourcePaths.count, 0);
    XCTAssertNil(error);
}

- (void)testRemoveNonExistingResourcePath
{
    _projectSettings.projectPath = @"/project/ccbuttonwooga.ccbproj";

    NSError *error;
    XCTAssertFalse([_projectSettings removeResourcePath:@"/project/test" error:&error]);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, SBResourcePathNotInProjectError);
}

- (void)testMoveResourcePath
{
    _projectSettings.projectPath = @"/project/ccbuttonwooga.ccbproj";

    NSString *pathOld = @"/somewhere/path_old";
    [_projectSettings addResourcePath:pathOld error:nil];

    NSString *pathNew = @"/somewhere/path_new";
    NSError *error;
    XCTAssertTrue([_projectSettings moveResourcePathFrom:pathOld toPath:pathNew error:&error]);
    XCTAssertNil(error);

    XCTAssertFalse([_projectSettings isResourcePathInProject:pathOld]);
    XCTAssertTrue([_projectSettings isResourcePathInProject:pathNew]);
}

- (void)testMoveResourcePathFailingBecauseThereIsAlreadyOneWithTheSameName
{
    NSString *path1 = @"/somewhere/path1";
    [_projectSettings addResourcePath:path1 error:nil];
    NSString *path2 = @"/somewhere/path2";
    [_projectSettings addResourcePath:path2 error:nil];

    NSError *error;
    XCTAssertFalse([_projectSettings moveResourcePathFrom:path1 toPath:path2 error:&error]);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, SBDuplicateResourcePathError);
}

- (void)testFullPathForPackageName
{
    NSString *packageName = @"foo";
    NSString *fullPackagesPath = [_projectSettings.projectPathDir stringByAppendingPathComponent:PACKAGES_FOLDER_NAME];

    NSString *fullPathForPackageName = [_projectSettings fullPathForPackageName:packageName];
    NSString *supposedFullPath = [fullPackagesPath stringByAppendingPathComponent:[packageName stringByAppendingPackageSuffix]];

    SBAssertStringsEqual(fullPathForPackageName,supposedFullPath);
}

- (void)testIsPathWithinPackagesFolder
{
    NSString *pathWithinPackagesFolder = [_projectSettings.packagesFolderPath stringByAppendingPathComponent:@"foo"];

    XCTAssertTrue([_projectSettings isPathInPackagesFolder:pathWithinPackagesFolder]);
}

- (void)testPackagesFolderPath
{
    NSString *fullPackagesPath = [_projectSettings.projectPathDir stringByAppendingPathComponent:PACKAGES_FOLDER_NAME];

    SBAssertStringsEqual(fullPackagesPath, _projectSettings.packagesFolderPath);
}

- (void)testInitWithDictionary
{
   NSDictionary *projectDict =
   @{
      @"deviceOrientationPortrait":@(NO),
      @"publishDirectory":@"Source/Resources/Published-iOS",
      @"resourceAutoScaleFactor":@(0),
      @"resourceProperties":@{
         @"":@{
            @"previewFolderHidden":@(YES)
         },
         @"ccbResources/ccbSliderBgHighlighted.png":@{
            @"tabletScale":@(1),
            @"scaleFrom":@(2)
         },
         @"ccbResources/ccbButtonHighlighted.png":@{
            @"tabletScale":@(1),
            @"scaleFrom":@(2)
         },
         @"Sprites" : @{},
         @"ccbResources/ccbSliderBgNormal.png":@{
            @"tabletScale":@(1),
            @"scaleFrom":@(2)
         },
         @"ccbResources/ccbTextField.png":@{
            @"tabletScale":@(1),
            @"scaleFrom":@(2)
         },
         @"ccbResources/ccbParticleFire.png":@{
            @"tabletScale":@(1),
            @"scaleFrom":@(1)
         },
         @"ccbResources":@{
            @"previewFolderHidden":@(YES)
         },
         @"ccbResources/ccbParticleMagic.png":@{
            @"tabletScale":@(1),
            @"scaleFrom":@(1)
         },
         @"ccbResources/ccbButtonNormal.png":@{
            @"tabletScale":@(1),
            @"scaleFrom":@(2)
         },
         @"ccbResources/ccbParticleStars.png":@{
            @"tabletScale":@(1),
            @"scaleFrom":@(1)
         },
         @"ccbResources/ccbSliderHandle.png":@{
            @"tabletScale":@(1),
            @"scaleFrom":@(2)
         },
         @"ccbResources/ccbParticleSmoke.png":@{
            @"tabletScale":@(1),
            @"scaleFrom":@(1)
         },
         @"ccbResources/ccbParticleSnow.png":@{
            @"tabletScale":@(1),
            @"scaleFrom":@(1)
         }
      },
      @"publishDirectoryAndroid":@"Source/Resources/Published-Android",
      @"defaultOrientation":@(0),
      @"publishResolution_android_tablet":@(YES),
      @"publishEnabledAndroid":@(YES),
      @"publishResolution_ios_phonehd":@(YES),
      @"publishResolution_ios_tablet":@(YES),
      @"publishResolution_android_phone":@(YES),
      @"fileType":@"CocosBuilderProject",
      @"resourcePaths":@[
         @{
            @"path":@"packages/SpriteBuilder Resources.sbpack"
         }
      ],
      @"publishAudioQuality_android":@(4),
      @"deviceOrientationLandscapeLeft":@(YES),
      @"publishResolution_android_tablethd":@(YES),
      @"publishAudioQuality_ios":@(4),
      @"publishEnvironment":@(0),
      @"publishEnablediPhone":@(YES),
      @"publishToZipFile":@(NO),
      @"exporter":@"ccbi",
      @"versionStr":@"Version: 1.x\n-n GitHub: \nfcec170fc2\n",
      @"publishResolution_ios_phone":@(YES),
      @"publishResolution_ios_tablethd":@(YES),
      @"deviceOrientationUpsideDown":@(NO),
      @"publishResolution_android_phonehd":@(YES),
      @"deviceOrientationLandscapeRight":@(YES),
      @"onlyPublishCCBs":@(NO),
      @"deviceScaling":@(0),
      @"excludedFromPackageMigration":@(YES),
      @"designTarget":@(0),
      @"cocos@(2)dUpdateIgnoredVersions":@[],
      @"engine":@(0)
   };

    ProjectSettings *project = [[ProjectSettings alloc] initWithSerialization:projectDict];

    XCTAssertFalse(project.deviceOrientationPortrait);
    XCTAssertFalse(project.deviceOrientationUpsideDown);
    XCTAssertTrue(project.deviceOrientationLandscapeLeft);
    XCTAssertTrue(project.deviceOrientationLandscapeRight);

    // This a convention, if it's read as 0 has to become 4
    XCTAssertEqual(project.resourceAutoScaleFactor, 4);
    SBAssertStringsEqual(project.publishDirectory, @"Source/Resources/Published-iOS");

    SBAssertStringsEqual(project.publishDirectoryAndroid, @"Source/Resources/Published-Android");
    XCTAssertEqual(project.defaultOrientation, 0);

    XCTAssertTrue(project.publishEnabledAndroid);
    XCTAssertTrue(project.publishResolution_android_phone);
    XCTAssertTrue(project.publishResolution_android_phonehd);
    XCTAssertTrue(project.publishResolution_android_tablet);
    XCTAssertTrue(project.publishResolution_android_tablethd);

    XCTAssertTrue(project.publishEnabledIOS);
    XCTAssertTrue(project.publishResolution_ios_phone);
    XCTAssertTrue(project.publishResolution_ios_phonehd);
    XCTAssertTrue(project.publishResolution_ios_tablet);
    XCTAssertTrue(project.publishResolution_ios_tablethd);

    [self assertResourcePaths:@[@"packages/SpriteBuilder Resources.sbpack"] inProject:project];

    XCTAssertEqual(project.publishAudioQuality_android, 4);
    XCTAssertEqual(project.publishAudioQuality_ios, 4);

    XCTAssertFalse(project.onlyPublishCCBs);
    XCTAssertEqual(project.deviceScaling, 0);
    XCTAssertEqual(project.designTarget, 0);

    XCTAssertEqual(project.engine, CCBTargetEngineCocos2d);
    SBAssertStringsEqual(project.exporter, @"ccbi");

    XCTAssertFalse(project.publishToZipFile);
    XCTAssertEqual(project.publishEnvironment, kCCBPublishEnvironmentDevelop);

    XCTAssertTrue(project.excludedFromPackageMigration);

    NSNumber *scaleFrom = [project propertyForRelPath:@"ccbResources/ccbSliderBgNormal.png" andKey:@"scaleFrom"];
    XCTAssertTrue([scaleFrom isEqualToNumber:@(2)]);
}

- (void)testWrongFileType
{
    NSDictionary *projectDict =
    @{
        @"fileType" : @"fooooo"
    };

    ProjectSettings *project = [[ProjectSettings alloc] initWithSerialization:projectDict];
    XCTAssertNil(project);
}

- (void)testWithSomeMissingKeyAndValues
{
    NSDictionary *projectDict =
    @{
       @"fileType":@"CocosBuilderProject"
    };

    ProjectSettings *project = [[ProjectSettings alloc] initWithSerialization:projectDict];
    XCTAssertNotNil(project);
    XCTAssertEqual(project.publishAudioQuality_android, DEFAULT_AUDIO_QUALITY);
    XCTAssertEqual(project.publishAudioQuality_ios, DEFAULT_AUDIO_QUALITY);
    SBAssertStringsEqual(project.publishDirectory, @"");
    SBAssertStringsEqual(project.publishDirectoryAndroid, @"");
    XCTAssertFalse(project.excludedFromPackageMigration);
}

- (void)testStandardInitializerAndPersistency
{
    NSString *fullPath = [self fullPathForFile:@"project.ccbproj"];;
    ProjectSettings *projectSettings = [[ProjectSettings alloc] init];
    projectSettings.projectPath = fullPath;

    XCTAssertTrue([projectSettings store], @"Failed to persist project at path \"%@\"", projectSettings.projectPath);


    [self assertFileExists:projectSettings.projectPath];

    NSMutableDictionary *projectDict = [NSMutableDictionary dictionaryWithContentsOfFile:fullPath];
    projectSettings = [[ProjectSettings alloc] initWithSerialization:projectDict];

    XCTAssertNotNil(projectSettings.resourcePaths);
    XCTAssertEqual(projectSettings.resourcePaths.count, 0);
    XCTAssertEqual(projectSettings.engine, CCBTargetEngineCocos2d);
    SBAssertStringsEqual(projectSettings.publishDirectory, @"Published-iOS");
    SBAssertStringsEqual(projectSettings.publishDirectoryAndroid, @"Published-Android");

    XCTAssertFalse(projectSettings.onlyPublishCCBs);
    XCTAssertFalse(projectSettings.publishToZipFile);

    XCTAssertTrue(projectSettings.deviceOrientationLandscapeLeft);
    XCTAssertTrue(projectSettings.deviceOrientationLandscapeRight);

    XCTAssertEqual(projectSettings.resourceAutoScaleFactor, 4);
    XCTAssertTrue(projectSettings.publishEnabledIOS);
    XCTAssertTrue(projectSettings.publishEnabledAndroid);

    XCTAssertTrue(projectSettings.publishResolution_ios_phone);
    XCTAssertTrue(projectSettings.publishResolution_ios_phonehd);
    XCTAssertTrue(projectSettings.publishResolution_ios_tablet);
    XCTAssertTrue(projectSettings.publishResolution_ios_tablethd);

    XCTAssertTrue(projectSettings.publishResolution_android_phone);
    XCTAssertTrue(projectSettings.publishResolution_android_phonehd);
    XCTAssertTrue(projectSettings.publishResolution_android_tablet);
    XCTAssertTrue(projectSettings.publishResolution_android_tablethd);

    XCTAssertEqual(projectSettings.publishEnvironment, kCCBPublishEnvironmentDevelop);
    XCTAssertEqual(projectSettings.publishAudioQuality_ios, 4);
    XCTAssertEqual(projectSettings.publishAudioQuality_android, 4);

    XCTAssertEqual(projectSettings.tabletPositionScaleFactor, 2.0f);

    XCTAssertFalse(projectSettings.excludedFromPackageMigration);
}

- (void)testResourcePathsAndPersistency
{
    NSString *fullPath = [self fullPathForFile:@"project.ccbproj"];;
    ProjectSettings *projectSettings = [[ProjectSettings alloc] init];
    projectSettings.projectPath = fullPath;

    NSString *resPath1 = [self fullPathForFile:@"1234567/890"];
    NSString *resPath2 = [self fullPathForFile:@"foo/baa/yeehaaa"];

    [projectSettings addResourcePath:resPath1 error:nil];
    [projectSettings addResourcePath:resPath2 error:nil];

    XCTAssertTrue([projectSettings store], @"Failed to persist project at path \"%@\"", projectSettings.projectPath);


    NSMutableDictionary *projectDict = [NSMutableDictionary dictionaryWithContentsOfFile:fullPath];
    projectSettings = [[ProjectSettings alloc] initWithSerialization:projectDict];
    projectSettings.projectPath = fullPath;

    [self assertResourcePaths:@[resPath1, resPath2] inProject:projectSettings];
}

- (void)testResourcePropertiesAndPersistency
{
    NSString *fullPath = [self fullPathForFile:@"project.ccbproj"];;
    ProjectSettings *projectSettings = [[ProjectSettings alloc] init];
    projectSettings.projectPath = fullPath;

    [projectSettings setProperty:@(kCCBPublishFormatSound_ios_mp4) forRelPath:@"foo/ping.wav" andKey:@"format_ios_sound"];

    XCTAssertTrue([projectSettings store], @"Failed to persist project at path \"%@\"", projectSettings.projectPath);


    NSMutableDictionary *projectDict = [NSMutableDictionary dictionaryWithContentsOfFile:fullPath];
    projectSettings = [[ProjectSettings alloc] initWithSerialization:projectDict];
    projectSettings.projectPath = fullPath;

    NSNumber *value = [projectSettings propertyForRelPath:@"foo/ping.wav" andKey:@"format_ios_sound"];
    XCTAssertEqual([value integerValue], (NSInteger)kCCBPublishFormatSound_ios_mp4);
}


// This test exists to ensure noone changes enum values by mistake that are persisted and have to
// be migrated with more effort to fix this change later on
- (void)testEnums
{
    XCTAssertEqual(kCCBPublishEnvironmentDevelop, 0, @"Enum value kCCBPublishEnvironmentDevelop  must not change");
    XCTAssertEqual(kCCBPublishEnvironmentRelease, 1, @"Enum value kCCBPublishEnvironmentRelease  must not change");

    XCTAssertEqual(CCBTargetEngineCocos2d, 0, @"Enum value CCBTargetEngineCocos2d  must not change");
    XCTAssertEqual(CCBTargetEngineSpriteKit, 1, @"Enum value CCBTargetEngineSpriteKit  must not change");

    XCTAssertEqual(kCCBOrientationLandscape, 0, @"Enum value kCCBOrientationLandscape  must not change");
    XCTAssertEqual(kCCBOrientationPortrait, 1, @"Enum value kCCBOrientationPortrait  must not change");

    XCTAssertEqual(kCCBDesignTargetFlexible, 0, @"Enum value kCCBDesignTargetFlexible  must not change");
    XCTAssertEqual(kCCBDesignTargetFixed, 1, @"Enum value kCCBDesignTargetFixed  must not change");
}

- (void)testRelativePathFromAbsolutePath
{
    [_projectSettings addResourcePath:[self fullPathForFile:@"Packages/foo.sbpack"] error:nil];
    [_projectSettings addResourcePath:[self fullPathForFile:@"Packages/baa.sbpack"] error:nil];

    NSString *fullPath = [self fullPathForFile:@"Packages/foo.sbpack/sprites/fighter.png"];
    SBAssertStringsEqual([_projectSettings findRelativePathInPackagesForAbsolutePath:fullPath], @"sprites/fighter.png");

    NSString *fullPath2 = [self fullPathForFile:@"Packages/level1.sbpack/sprites/fighter.png"];
    XCTAssertNil([_projectSettings findRelativePathInPackagesForAbsolutePath:fullPath2]);
}

- (void)testConvenienceMethodForAudioQualityOfResources
{
    NSInteger quality = [_projectSettings soundQualityForRelPath:@"foo" osType:kCCBPublisherOSTypeAndroid];
    XCTAssertEqual(quality, NSNotFound);

    [_projectSettings setProperty:@(7) forRelPath:@"baa" andKey:@"format_android_sound_quality"];
    int quality2 = [_projectSettings soundQualityForRelPath:@"baa" osType:kCCBPublisherOSTypeAndroid];
    XCTAssertEqual(quality2, 7);
}

- (void)testConvenienceMethodForAudioQuality
{
    _projectSettings.publishAudioQuality_android = 8;
    _projectSettings.publishAudioQuality_ios = 6;

    XCTAssertEqual([_projectSettings audioQualityForOsType:kCCBPublisherOSTypeAndroid], 8);
    XCTAssertEqual([_projectSettings audioQualityForOsType:kCCBPublisherOSTypeIOS], 6);
}

- (void)testMarkAsDirty
{
    RMResource *res1 = [[RMResource alloc] initWithFilePath:[self fullPathForFile:@"project/Packages/package1.sbpack/foo.png"]];
    RMResource *res2 = [[RMResource alloc] initWithFilePath:[self fullPathForFile:@"project/Packages/package1.sbpack/baa.png"]];
    RMResource *res3 = [[RMResource alloc] initWithFilePath:[self fullPathForFile:@"project/Packages/package1.sbpack/123.png"]];

    ResourceManager *resourceManager = [ResourceManager sharedManager];
    [resourceManager setActiveDirectoriesWithFullReset:@[
            [self fullPathForFile:@"project/Packages/package1.sbpack"],
    ]];

    [_projectSettings addResourcePath:@"project/Packages/package1.sbpack" error:nil];
    [_projectSettings clearAllDirtyMarkers];


    // Test clear all dirty markers
    [_projectSettings markAsDirtyResource:res1];
    [_projectSettings markAsDirtyResource:res2];
    [_projectSettings markAsDirtyResource:res3];

    [_projectSettings clearAllDirtyMarkers];

    XCTAssertFalse([_projectSettings isDirtyResource:res1]);
    XCTAssertFalse([_projectSettings isDirtyResource:res2]);
    XCTAssertFalse([_projectSettings isDirtyResource:res3]);


    // Setting a new value should mark the resource as dirty
    XCTAssertFalse([_projectSettings isDirtyResource:res1]);

    [_projectSettings setProperty:@(1) forResource:res1 andKey:@"format_ios"];

    XCTAssertTrue([_projectSettings isDirtyResource:res1]);


    // Removing a property should mark the resource as dirty
    [_projectSettings clearAllDirtyMarkers];

    [_projectSettings removePropertyForResource:res1 andKey:@"format_ios"];

    XCTAssertTrue([_projectSettings isDirtyResource:res1]);


    // Setting same value twice should not mark resource as dirty
    [_projectSettings clearAllDirtyMarkers];

    [_projectSettings setProperty:@(1) forResource:res1 andKey:@"format_ios"];

    [_projectSettings clearAllDirtyMarkers];

    XCTAssertFalse([_projectSettings isDirtyResource:res1]);

    [_projectSettings setProperty:@(1) forResource:res1 andKey:@"format_ios"];

    XCTAssertFalse([_projectSettings isDirtyResource:res1]);
}


#pragma mark - test helper

- (void)assertResourcePaths:(NSArray *)resourcePaths inProject:(ProjectSettings *)project
{
    for (NSString *resourcePath in resourcePaths)
    {
        XCTAssertTrue([project isResourcePathInProject:resourcePath], @"Resource path \"%@\"is not in project settings. Present in settings: %@", resourcePath, project.resourcePaths);
    }
}

@end
