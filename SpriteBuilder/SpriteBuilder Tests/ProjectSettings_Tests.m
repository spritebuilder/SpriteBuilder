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
#import "Errors.h"
#import "ProjectSettings+Packages.h"
#import "NSString+Packages.h"
#import "MiscConstants.h"
#import "FileSystemTestCase.h"
#import "ProjectSettings+Convenience.h"
#import "RMResource.h"
#import "ResourceManager.h"
#import "ResourceManagerUtil.h"
#import "ResourceTypes.h"
#import "RMDirectory.h"
#import "ResourcePropertyKeys.h"

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

    XCTAssertEqualObjects(fullPathForPackageName,supposedFullPath);
}

- (void)testIsPathWithinPackagesFolder
{
    NSString *pathWithinPackagesFolder = [_projectSettings.packagesFolderPath stringByAppendingPathComponent:@"foo"];

    XCTAssertTrue([_projectSettings isPathInPackagesFolder:pathWithinPackagesFolder]);
}

- (void)testPackagesFolderPath
{
    NSString *fullPackagesPath = [_projectSettings.projectPathDir stringByAppendingPathComponent:PACKAGES_FOLDER_NAME];

    XCTAssertEqualObjects(fullPackagesPath, _projectSettings.packagesFolderPath);
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
                   RESOURCE_PROPERTY_IMAGE_SCALE_FROM:@(2),
                   RESOURCE_PROPERTY_IMAGE_USEUISCALE:@(YES)
         },
         @"ccbResources/ccbButtonHighlighted.png":@{
                   RESOURCE_PROPERTY_IMAGE_SCALE_FROM:@(2),
                   RESOURCE_PROPERTY_IMAGE_USEUISCALE:@(YES)
         },
         @"Sprites" : @{},
         @"ccbResources/ccbSliderBgNormal.png":@{
                   RESOURCE_PROPERTY_IMAGE_SCALE_FROM:@(2),
                   RESOURCE_PROPERTY_IMAGE_USEUISCALE:@(YES)
         },
         @"ccbResources/ccbTextField.png":@{
                   RESOURCE_PROPERTY_IMAGE_SCALE_FROM:@(2),
                   RESOURCE_PROPERTY_IMAGE_USEUISCALE:@(YES)
         },
         @"ccbResources/ccbParticleFire.png":@{
                   RESOURCE_PROPERTY_IMAGE_SCALE_FROM:@(2),
                   RESOURCE_PROPERTY_IMAGE_USEUISCALE:@(YES)
         },
         @"ccbResources":@{
            @"previewFolderHidden":@(YES)
         },
         @"ccbResources/ccbParticleMagic.png":@{
                   RESOURCE_PROPERTY_IMAGE_SCALE_FROM:@(2),
                   RESOURCE_PROPERTY_IMAGE_USEUISCALE:@(YES)
         },
         @"ccbResources/ccbButtonNormal.png":@{
                   RESOURCE_PROPERTY_IMAGE_SCALE_FROM:@(2),
                   RESOURCE_PROPERTY_IMAGE_USEUISCALE:@(YES)
         },
         @"ccbResources/ccbParticleStars.png":@{
                   RESOURCE_PROPERTY_IMAGE_SCALE_FROM:@(2),
                   RESOURCE_PROPERTY_IMAGE_USEUISCALE:@(YES)
         },
         @"ccbResources/ccbSliderHandle.png":@{
                   RESOURCE_PROPERTY_IMAGE_SCALE_FROM:@(2),
                   RESOURCE_PROPERTY_IMAGE_USEUISCALE:@(YES)
         },
         @"ccbResources/ccbParticleSmoke.png":@{
                   RESOURCE_PROPERTY_IMAGE_SCALE_FROM:@(2),
                   RESOURCE_PROPERTY_IMAGE_USEUISCALE:@(YES)
         },
         @"ccbResources/ccbParticleSnow.png":@{
                   RESOURCE_PROPERTY_IMAGE_SCALE_FROM:@(2),
                   RESOURCE_PROPERTY_IMAGE_USEUISCALE:@(YES)
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
      @"deviceOrientationLandscapeLeft":@(YES),
      @"publishResolution_android_tablethd":@(YES),
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
    XCTAssertEqualObjects(project.publishDirectory, @"Source/Resources/Published-iOS");

    XCTAssertEqualObjects(project.publishDirectoryAndroid, @"Source/Resources/Published-Android");
    XCTAssertEqual(project.defaultOrientation, 0);

    XCTAssertTrue(project.publishEnabledAndroid);
    XCTAssertTrue(project.publishEnabledIOS);

    [self assertResourcePaths:@[@"packages/SpriteBuilder Resources.sbpack"] inProject:project];

    XCTAssertFalse(project.onlyPublishCCBs);
    XCTAssertEqual(project.deviceScaling, 0);
    XCTAssertEqual(project.designTarget, 0);

    XCTAssertEqual(project.engine, SBTargetEngineCocos2d);
    XCTAssertEqualObjects(project.exporter, @"ccbi");

    XCTAssertFalse(project.publishToZipFile);
    XCTAssertEqual(project.publishEnvironment, kCCBPublishEnvironmentDevelop);

    NSNumber *scaleFrom = [project propertyForRelPath:@"ccbResources/ccbSliderBgNormal.png" andKey:RESOURCE_PROPERTY_IMAGE_SCALE_FROM];
    XCTAssertTrue([scaleFrom isEqualToNumber:@(2)]);

    NSNumber *useUIScale = [project propertyForRelPath:@"ccbResources/ccbSliderBgNormal.png" andKey:RESOURCE_PROPERTY_IMAGE_USEUISCALE];
    XCTAssertTrue([useUIScale boolValue]);
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
    XCTAssertEqualObjects(project.publishDirectory, @"");
    XCTAssertEqualObjects(project.publishDirectoryAndroid, @"");
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
    XCTAssertEqual(projectSettings.engine, SBTargetEngineCocos2d);
    XCTAssertEqualObjects(projectSettings.publishDirectory, @"Published-iOS");
    XCTAssertEqualObjects(projectSettings.publishDirectoryAndroid, @"Published-Android");

    XCTAssertFalse(projectSettings.onlyPublishCCBs);
    XCTAssertFalse(projectSettings.publishToZipFile);

    XCTAssertTrue(projectSettings.deviceOrientationLandscapeLeft);
    XCTAssertTrue(projectSettings.deviceOrientationLandscapeRight);

    XCTAssertTrue(projectSettings.publishEnabledIOS);
    XCTAssertTrue(projectSettings.publishEnabledAndroid);

    XCTAssertEqual(projectSettings.publishEnvironment, kCCBPublishEnvironmentDevelop);

    XCTAssertEqual(projectSettings.tabletPositionScaleFactor, 2.0f);
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

    [projectSettings setProperty:@(kCCBPublishFormatSound_ios_mp4) forRelPath:@"foo/ping.wav" andKey:RESOURCE_PROPERTY_IOS_SOUND];

    XCTAssertTrue([projectSettings store], @"Failed to persist project at path \"%@\"", projectSettings.projectPath);


    NSMutableDictionary *projectDict = [NSMutableDictionary dictionaryWithContentsOfFile:fullPath];
    projectSettings = [[ProjectSettings alloc] initWithSerialization:projectDict];
    projectSettings.projectPath = fullPath;

    NSNumber *value = [projectSettings propertyForRelPath:@"foo/ping.wav" andKey:RESOURCE_PROPERTY_IOS_SOUND];
    XCTAssertEqual([value integerValue], (NSInteger)kCCBPublishFormatSound_ios_mp4);
}


// This test exists to ensure noone changes enum values by mistake that are persisted and have to
// be migrated with more effort to fix this change later on
- (void)testEnums
{
    XCTAssertEqual(kCCBPublishEnvironmentDevelop, 0, @"Enum value kSBPublishEnvironmentDevelop  must not change");
    XCTAssertEqual(kCCBPublishEnvironmentRelease, 1, @"Enum value kSBPublishEnvironmentRelease  must not change");

    XCTAssertEqual(SBTargetEngineCocos2d, 0, @"Enum value SBTargetEngineCocos2d  must not change");

    XCTAssertEqual(kSBOrientationLandscape, 0, @"Enum value kSBOrientationLandscape  must not change");
    XCTAssertEqual(kSBOrientationPortrait, 1, @"Enum value kSBOrientationPortrait  must not change");

    XCTAssertEqual(kSBDesignTargetFlexible, 0, @"Enum value kSBDesignTargetFlexible  must not change");
    XCTAssertEqual(kSBDesignTargetFixed, 1, @"Enum value kSBDesignTargetFixed  must not change");
}

- (void)testRelativePathFromAbsolutePath
{
    [_projectSettings addResourcePath:[self fullPathForFile:@"Packages/foo.sbpack"] error:nil];
    [_projectSettings addResourcePath:[self fullPathForFile:@"Packages/baa.sbpack"] error:nil];

    NSString *fullPath = [self fullPathForFile:@"Packages/foo.sbpack/sprites/fighter.png"];
    XCTAssertEqualObjects([_projectSettings findRelativePathInPackagesForAbsolutePath:fullPath], @"sprites/fighter.png");

    NSString *fullPath2 = [self fullPathForFile:@"Packages/level1.sbpack/sprites/fighter.png"];
    XCTAssertNil([_projectSettings findRelativePathInPackagesForAbsolutePath:fullPath2]);
}

- (void)testConvenienceMethodForAudioQualityOfResources
{
    NSInteger quality = [_projectSettings soundQualityForRelPath:@"foo" osType:kCCBPublisherOSTypeAndroid];
    XCTAssertEqual(quality, NSNotFound);

    [_projectSettings setProperty:@(7) forRelPath:@"baa" andKey:RESOURCE_PROPERTY_ANDROID_SOUND_QUALITY];
    NSInteger quality2 = [_projectSettings soundQualityForRelPath:@"baa" osType:kCCBPublisherOSTypeAndroid];
    XCTAssertEqual(quality2, 7);
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

    [_projectSettings setProperty:@(1) forResource:res1 andKey:RESOURCE_PROPERTY_IOS_IMAGE_FORMAT];

    XCTAssertTrue([_projectSettings isDirtyResource:res1]);


    // Removing a property should mark the resource as dirty
    [_projectSettings clearAllDirtyMarkers];

    [_projectSettings removePropertyForResource:res1 andKey:RESOURCE_PROPERTY_IOS_IMAGE_FORMAT];

    XCTAssertTrue([_projectSettings isDirtyResource:res1]);


    // Setting same value twice should not mark resource as dirty
    [_projectSettings clearAllDirtyMarkers];

    [_projectSettings setProperty:@(1) forResource:res1 andKey:RESOURCE_PROPERTY_IOS_IMAGE_FORMAT];
    [_projectSettings setProperty:@(1) forResource:res1 andKey:RESOURCE_PROPERTY_IMAGE_SCALE_FROM];
    [_projectSettings setProperty:@(YES) forResource:res1 andKey:RESOURCE_PROPERTY_IMAGE_USEUISCALE];

    [_projectSettings clearAllDirtyMarkers];

    XCTAssertFalse([_projectSettings isDirtyResource:res1]);

    [_projectSettings setProperty:@(1) forResource:res1 andKey:RESOURCE_PROPERTY_IOS_IMAGE_FORMAT];
    [_projectSettings setProperty:@(1) forResource:res1 andKey:RESOURCE_PROPERTY_IMAGE_SCALE_FROM];
    [_projectSettings setProperty:@(YES) forResource:res1 andKey:RESOURCE_PROPERTY_IMAGE_USEUISCALE];

    XCTAssertFalse([_projectSettings isDirtyResource:res1]);
}

- (void)testMarkSpriteSheetDirtyIfNewOrRemovedImage
{
    NSString *REL_PACKAGE_PATH = @"project/Packages/package1.sbpack";
    NSString *REL_SPRITESHEET_PATH = @"project/Packages/package1.sbpack/spritesheet";
    NSString *REL_IMAGE_IN_SPRITESHEET_PATH = @"project/Packages/package1.sbpack/spritesheet/image.png";
    NSString *REL_IMAGE_NOT_IN_SPRITESHEET_PATH = @"project/Packages/package1.sbpack/image.png";

    _projectSettings.projectPath = [self fullPathForFile:@"project/abc.ccbproj"];
    [_projectSettings addResourcePath:[self fullPathForFile:REL_PACKAGE_PATH] error:nil];

    ResourceManager *resourceManager = [ResourceManager sharedManager];
    [resourceManager setActiveDirectoriesWithFullReset:@[[self fullPathForFile:REL_PACKAGE_PATH]]];

    RMDirectory *directory = [[RMDirectory alloc] init];
    directory.dirPath = [self fullPathForFile:REL_SPRITESHEET_PATH];
    directory.projectSettings = _projectSettings;

    RMResource *spriteSheet = [[RMResource alloc] initWithFilePath:[self fullPathForFile:REL_SPRITESHEET_PATH]];
    spriteSheet.type = kCCBResTypeDirectory;
    spriteSheet.data = directory;

    [_projectSettings makeSmartSpriteSheet:spriteSheet];

    RMResource *imageInSpriteSheet = [[RMResource alloc] initWithFilePath:[self fullPathForFile:REL_IMAGE_IN_SPRITESHEET_PATH]];
    imageInSpriteSheet.type = kCCBResTypeImage;

    RMResource *image = [[RMResource alloc] initWithFilePath:[self fullPathForFile:REL_IMAGE_NOT_IN_SPRITESHEET_PATH]];
    image.type = kCCBResTypeImage;

    RMDirectory *activeDir = [resourceManager activeDirectoryForPath:[self fullPathForFile:REL_PACKAGE_PATH]];
    [activeDir.any addObject:image];
    [activeDir.any addObject:imageInSpriteSheet];
    [activeDir.any addObject:spriteSheet];
    [activeDir.images addObject:image];
    [activeDir.images addObject:imageInSpriteSheet];
    [activeDir.images addObject:spriteSheet];

    [_projectSettings clearAllDirtyMarkers];

    // Move from sprite sheet to another location
    NSString *fullPathToSomeDir = [self fullPathForFile:[REL_PACKAGE_PATH stringByAppendingPathComponent:@"foo"]];

    [_projectSettings movedResourceFrom:[ResourceManagerUtil relativePathFromAbsolutePath:imageInSpriteSheet.filePath]
                                     to:[ResourceManagerUtil relativePathFromAbsolutePath:fullPathToSomeDir]
                           fromFullPath:imageInSpriteSheet.filePath
                             toFullPath:fullPathToSomeDir];

    XCTAssertTrue([_projectSettings isDirtyRelPath:@"spritesheet"]);


    [_projectSettings clearAllDirtyMarkers];

    // Move to sprite sheet from outside
    NSString *fullPathToInSpriteSheet = [self fullPathForFile:REL_IMAGE_IN_SPRITESHEET_PATH];
    [_projectSettings movedResourceFrom:[ResourceManagerUtil relativePathFromAbsolutePath:image.filePath]
                                     to:[ResourceManagerUtil relativePathFromAbsolutePath:fullPathToInSpriteSheet]
                           fromFullPath:image.filePath
                             toFullPath:fullPathToInSpriteSheet];

    XCTAssertTrue([_projectSettings isDirtyRelPath:@"spritesheet"]);


    // Move to sprite sheet from outside
    [_projectSettings clearAllDirtyMarkers];
    [_projectSettings movedResourceFrom:[ResourceManagerUtil relativePathFromAbsolutePath:image.filePath]
                                     to:[ResourceManagerUtil relativePathFromAbsolutePath:image.filePath]
                           fromFullPath:image.filePath
                             toFullPath:image.filePath];

    XCTAssertFalse([_projectSettings isDirtyRelPath:@"spritesheet"]);


    // Image deleted
    [_projectSettings clearAllDirtyMarkers];
    [_projectSettings removedResourceAt:[ResourceManagerUtil relativePathFromAbsolutePath:imageInSpriteSheet.filePath]];

    XCTAssertTrue([_projectSettings isDirtyRelPath:@"spritesheet"]);
}

- (void)testClearDirtyMarker
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

    [_projectSettings markAsDirtyResource:res1];
    [_projectSettings markAsDirtyResource:res2];
    [_projectSettings markAsDirtyResource:res3];

    XCTAssertTrue([_projectSettings isDirtyResource:res1]);
    XCTAssertTrue([_projectSettings isDirtyResource:res2]);
    XCTAssertTrue([_projectSettings isDirtyResource:res3]);

    [_projectSettings clearDirtyMarkerOfResource:res1];
    [_projectSettings clearDirtyMarkerOfResource:res2];

    XCTAssertFalse([_projectSettings isDirtyResource:res1]);
    XCTAssertFalse([_projectSettings isDirtyResource:res2]);
    XCTAssertTrue([_projectSettings isDirtyResource:res3]);
}

- (void)testInitWithFilename
{
    [self createProjectSettingsFileWithName:@"foo.spritebuilder/foo.ccbproj"];

    [self assertFileExists:@"foo.spritebuilder/foo.ccbproj"];

    ProjectSettings *projectSettings = [[ProjectSettings alloc] initWithFilepath:[self fullPathForFile:@"foo.spritebuilder/foo.ccbproj"]];

    XCTAssertEqualObjects(projectSettings.projectName, @"foo");
    XCTAssertNotNil(projectSettings);
    XCTAssertEqualObjects(projectSettings.projectPath, [self fullPathForFile:@"foo.spritebuilder/foo.ccbproj"]);
}

- (void)testInitWithFilenameFailing_fileDoesNotExist
{
    ProjectSettings *projectSettings = [[ProjectSettings alloc] initWithFilepath:[self fullPathForFile:@"foo.spritebuilder/doesnotexist.ccbproj"]];

    XCTAssertNil(projectSettings);
}

- (void)testInitWithFilenameFailing_malformedPropertyList
{
    NSDictionary *somedict = @{
        @"asdasd" : @"hahahahahha"
    };

    [somedict writeToFile:[self fullPathForFile:[self fullPathForFile:@"foo.spritebuilder/doesnotexist.ccbproj"]] atomically:YES];

    ProjectSettings *projectSettings = [[ProjectSettings alloc] initWithFilepath:[self fullPathForFile:@"foo.spritebuilder/doesnotexist.ccbproj"]];

    XCTAssertNil(projectSettings);
};

#pragma mark - test helper

- (void)assertResourcePaths:(NSArray *)resourcePaths inProject:(ProjectSettings *)project
{
    for (NSString *resourcePath in resourcePaths)
    {
        XCTAssertTrue([project isResourcePathInProject:resourcePath], @"Resource path \"%@\"is not in project settings. Present in settings: %@", resourcePath, project.resourcePaths);
    }
}

@end
