//
//  ProjectSettings_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 28.05.14.
//
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import "ProjectSettings.h"
#import "SBErrors.h"
#import "ProjectSettings+Packages.h"
#import "NSString+Packages.h"
#import "SBAssserts.h"
#import "MiscConstants.h"

@interface ProjectSettings_Tests : XCTestCase

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
      @"flattenPaths":@(NO),
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
    XCTAssertFalse(project.flattenPaths);

    SBAssertStringsEqual(project.publishDirectoryAndroid, @"Source/Resources/Published-Android");
    XCTAssertEqual(project.defaultOrientation, 0);

    XCTAssertTrue(project.publishEnabledAndroid);
    XCTAssertTrue(project.publishResolution_android_phone);
    XCTAssertTrue(project.publishResolution_android_phonehd);
    XCTAssertTrue(project.publishResolution_android_tablet);
    XCTAssertTrue(project.publishResolution_android_tablethd);

    XCTAssertTrue(project.publishEnablediPhone);
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
    XCTAssertEqual(project.publishEnvironment, PublishEnvironmentDevelop);

    XCTAssertTrue(project.excludedFromPackageMigration);

    NSNumber *scaleFrom = [project valueForRelPath:@"ccbResources/ccbSliderBgNormal.png" andKey:@"scaleFrom"];
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
    XCTAssertEqual(project.publishAudioQuality_android, 1);
    XCTAssertEqual(project.publishAudioQuality_ios, 1);
    SBAssertStringsEqual(project.publishDirectory, @"");
    SBAssertStringsEqual(project.publishDirectoryAndroid, @"");
    XCTAssertFalse(project.excludedFromPackageMigration);
}

// This test exists to ensure noone changes enum values by mistake that are persisted and have to
// be migrated with more effort to fix this change later on
- (void)testEnums
{
    XCTAssertEqual(PublishEnvironmentDevelop, 0);
    XCTAssertEqual(PublishEnvironmentRelease, 1);

    XCTAssertEqual(CCBTargetEngineCocos2d, 0);
    XCTAssertEqual(CCBTargetEngineSpriteKit, 1);

    XCTAssertEqual(kCCBOrientationLandscape, 0);
    XCTAssertEqual(kCCBOrientationPortrait, 1);

    XCTAssertEqual(kCCBDesignTargetFlexible, 0);
    XCTAssertEqual(kCCBDesignTargetFixed, 1);
}


#pragma mark - test helper

- (void)assertResourcePaths:(NSArray *)resourcePaths inProject:(ProjectSettings *)project
{
    for (NSString *resourcePath in resourcePaths)
    {
        XCTAssertTrue([project isResourcePathInProject:resourcePath], @"Resource path \"%@\"is not in project settings. Found in settings: %@", resourcePath, _projectSettings.resourcePaths);
    }
}

@end
