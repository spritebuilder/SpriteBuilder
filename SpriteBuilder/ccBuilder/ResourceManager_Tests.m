//
//  ResourceManager_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 02.09.14.
//
//

#import <XCTest/XCTest.h>
#import "ResourceManager.h"
#import "RMResource.h"
#import "FileSystemTestCase.h"
#import "RMDirectory.h"
#import "ResourceTypes.h"
#import "ProjectSettings.h"
#import "ResourceManagerUtil.h"
#import "RMPackage.h"
#import "SBAssserts.h"
#import "FileSystemTestCase+Images.h"
#import "ResourcePropertyKeys.h"
#import "SBPackageSettings.h"
#import "ResourceManager+Publishing.h"

@interface ResourceManager_Tests : FileSystemTestCase

@property (nonatomic, strong) ResourceManager *resourceManager;
@property (nonatomic, strong) ProjectSettings *projectSettings;

@end


@implementation ResourceManager_Tests

- (void)setUp
{
    [super setUp];

    self.resourceManager = [ResourceManager sharedManager];
    [_resourceManager setActiveDirectoriesWithFullReset:@[
            [self fullPathForFile:@"project/Packages/package1.sbpack"],
    ]];

    self.projectSettings = [[ProjectSettings alloc] init];
    _projectSettings.projectPath = [self fullPathForFile:@"project/foo.ccbproj"];
    [_projectSettings addResourcePath:[self fullPathForFile:@"project/Packages/package1.sbpack"] error:nil];
}

- (void)testResourceForRelativePath
{
    RMResource *image = [[RMResource alloc] initWithFilePath:[self fullPathForFile:@"project/Packages/package1.sbpack/image.png"]];

    RMDirectory *activeDirectory = [_resourceManager activeDirectoryForPath:[self fullPathForFile:@"project/Packages/package1.sbpack"]];
    [activeDirectory.any addObject:image];
    [activeDirectory.images addObject:image];

    RMResource *resource = [[ResourceManager sharedManager] resourceForRelPath:@"image.png"];

    XCTAssertTrue([image isEqual:resource]);
}

- (void)testIsResourceInSpriteSheet
{
    _resourceManager.projectSettings = _projectSettings;

    RMResource *audio = [[RMResource alloc] initWithFilePath:[self fullPathForFile:@"project/Packages/package1.sbpack/spritesheet/sound.wav"]];
    audio.type = kCCBResTypeAudio;

    XCTAssertFalse([_resourceManager isResourceInSpriteSheet:audio]);


    RMDirectory *activeDirectory = [_resourceManager activeDirectoryForPath:[self fullPathForFile:@"project/Packages/package1.sbpack"]];

    RMResource *image = [[RMResource alloc] initWithFilePath:[self fullPathForFile:@"project/Packages/package1.sbpack/spritesheet/image.png"]];
    image.type = kCCBResTypeImage;
    [activeDirectory.any addObject:image];
    [activeDirectory.images addObject:image];

    RMDirectory *spriteSheetData = [[RMDirectory alloc] init];
    spriteSheetData.projectSettings = _projectSettings;
    spriteSheetData.dirPath = [self fullPathForFile:@"project/Packages/package1.sbpack/spritesheet"];
    RMResource *spriteSheet = [[RMResource alloc] initWithFilePath:[self fullPathForFile:@"project/Packages/package1.sbpack/spritesheet"]];
    spriteSheet.type = kCCBResTypeDirectory;
    spriteSheet.data = spriteSheetData;
    [activeDirectory.any addObject:spriteSheet];
    [activeDirectory.images addObject:spriteSheet];

    [_projectSettings makeSmartSpriteSheet:spriteSheet];

    XCTAssertTrue([_resourceManager isResourceInSpriteSheet:image]);
}

- (void)testSpriteSheetContainingFullPathWithNonSpriteSheet
{
    _resourceManager.projectSettings = _projectSettings;

    RMDirectory *activeDirectory = [_resourceManager activeDirectoryForPath:[self fullPathForFile:@"project/Packages/package1.sbpack"]];

    RMResource *image = [[RMResource alloc] initWithFilePath:[self fullPathForFile:@"project/Packages/package1.sbpack/somedir/image.png"]];
    image.type = kCCBResTypeImage;
    [activeDirectory.any addObject:image];
    [activeDirectory.images addObject:image];

    RMDirectory *directoryData = [[RMDirectory alloc] init];
    directoryData.projectSettings = _projectSettings;
    directoryData.dirPath = [self fullPathForFile:@"project/Packages/package1.sbpack/somedir"];

    RMResource *directory = [[RMResource alloc] initWithFilePath:[self fullPathForFile:@"project/Packages/package1.sbpack/somedir"]];
    directory.type = kCCBResTypeDirectory;
    directory.data = directoryData;
    [activeDirectory.any addObject:directory];

    XCTAssertNil([_resourceManager spriteSheetContainingFullPath:image.filePath]);
}

- (void)testSpriteSheetContainingFullPathWithSpriteSheet
{
    _resourceManager.projectSettings = _projectSettings;

    RMDirectory *activeDirectory = [_resourceManager activeDirectoryForPath:[self fullPathForFile:@"project/Packages/package1.sbpack"]];

    RMResource *image = [[RMResource alloc] initWithFilePath:[self fullPathForFile:@"project/Packages/package1.sbpack/somedir/image.png"]];
    image.type = kCCBResTypeImage;
    [activeDirectory.any addObject:image];
    [activeDirectory.images addObject:image];

    RMDirectory *spriteSheetData = [[RMDirectory alloc] init];
    spriteSheetData.projectSettings = _projectSettings;
    spriteSheetData.dirPath = [self fullPathForFile:@"project/Packages/package1.sbpack/somedir"];

    RMResource *spriteSheet = [[RMResource alloc] initWithFilePath:[self fullPathForFile:@"project/Packages/package1.sbpack/somedir"]];
    spriteSheet.type = kCCBResTypeDirectory;
    spriteSheet.data = spriteSheetData;
    [activeDirectory.any addObject:spriteSheet];

    [_projectSettings makeSmartSpriteSheet:spriteSheet];

    RMResource *potentialSpriteSheet = [_resourceManager spriteSheetContainingFullPath:image.filePath];
    XCTAssertTrue([potentialSpriteSheet isSpriteSheet]);
}

- (void)testAllPackages
{
    NSArray *expectedPackagePaths = @[
        [self fullPathForFile:@"project/Packages/gigapackage.sbpack"],
        [self fullPathForFile:@"project/Packages/superpackage.sbpack"],
        [self fullPathForFile:@"project/Packages/ultrapackage.sbpack"],
    ];

    [self setupPackagesWithFullPaths:expectedPackagePaths];

    NSArray *allPackages = [_resourceManager allPackages];
    NSMutableArray *allPackagePaths = [NSMutableArray array];

    for (RMPackage *aPackage in allPackages)
    {
        [allPackagePaths addObject:aPackage.dirPath ];
    }

    XCTAssertTrue([allPackagePaths isEqualToArray:expectedPackagePaths]);
}

- (void)testPackageForPath
{
    NSArray *packages = @[
        [self fullPathForFile:@"project/Packages/foo.sbpack"],
        [self fullPathForFile:@"project/Packages/baa.sbpack"],
    ];

    [self setupPackagesWithFullPaths:packages];

    RMPackage *fooPackage = [_resourceManager packageForPath:[self fullPathForFile:@"project/Packages/foo.sbpack/images/resources-auto/sky.png"]];
    RMPackage *baaPackage = [_resourceManager packageForPath:[self fullPathForFile:@"project/Packages/baa.sbpack/spritesheets/deep/deeper/bottom.png"]];
    RMPackage *noPackage = [_resourceManager packageForPath:[self fullPathForFile:@"project/Packages/123.sbpack/images/resources-autp/sky.png"]];

    SBAssertStringsEqual(fooPackage.fullPath, [self fullPathForFile:@"project/Packages/foo.sbpack"]);
    SBAssertStringsEqual(baaPackage.fullPath, [self fullPathForFile:@"project/Packages/baa.sbpack"]);

    XCTAssertNil(noPackage);
}

- (void)testCreateCachedImageFromAutoPathWithPackageDefaultSrcScalingSet
{
    NSString *imgRelPath = @"project/Packages/foo.sbpack/resources-auto/original.png";
    [self setupPackagesWithFullPaths:@[[self fullPathForFile:@"project/Packages/foo.sbpack"]]];

    [self createPNGAtPath:imgRelPath width:20 height:20];

    [self setAllPackagesAutoSrcScalingTo:2];

    [_resourceManager createCachedImageFromAutoPath:[self fullPathForFile:imgRelPath]
                                             saveAs:[self fullPathForFile:@"resized.png"]
                                      forResolution:@(4)
                                    projectSettings:_projectSettings
                                    packageSettings:[_resourceManager loadAllPackageSettings]];

    [self assertPNGAtPath:[self fullPathForFile:@"resized.png"] hasWidth:40 hasHeight:40];
}

- (void)testCreateCachedImageFromAutoPathWithAssetSpecificScaling
{
    NSString *imgRelPath = @"project/Packages/foo.sbpack/resources-auto/original.png";
    [self setupPackagesWithFullPaths:@[[self fullPathForFile:@"project/Packages/foo.sbpack"]]];

    [self createPNGAtPath:imgRelPath width:5 height:5];

    [self setAllPackagesAutoSrcScalingTo:1];

    [_projectSettings setProperty:@1 forRelPath:@"original.png" andKey:RESOURCE_PROPERTY_IMAGE_SCALE_FROM];
    [_projectSettings setProperty:@YES forRelPath:@"original.png" andKey:RESOURCE_PROPERTY_IMAGE_USEUISCALE];

    [_resourceManager createCachedImageFromAutoPath:[self fullPathForFile:imgRelPath]
                                             saveAs:[self fullPathForFile:@"resized.png"]
                                      forResolution:@(4)
                                    projectSettings:_projectSettings
                                    packageSettings:[_resourceManager loadAllPackageSettings]];

    [self assertPNGAtPath:[self fullPathForFile:@"resized.png"] hasWidth:20 hasHeight:20];
}

- (void)setAllPackagesAutoSrcScalingTo:(NSInteger)autoScaling
{
    NSArray *allPackages = [_resourceManager allPackages];
    for (RMPackage *aPackage in allPackages)
    {
        SBPackageSettings *packageSettings = [[SBPackageSettings alloc] initWithPackage:aPackage];
        [packageSettings load];

        packageSettings.resourceAutoScaleFactor = autoScaling;
        [packageSettings store];
    }
}


#pragma mark - helper

// sets packages for resource manager and project settings
- (void)setupPackagesWithFullPaths:(NSArray *)packages
{
    self.resourceManager = [ResourceManager sharedManager];
    [_resourceManager setActiveDirectoriesWithFullReset:packages];

    self.projectSettings = [[ProjectSettings alloc] init];
    _projectSettings.projectPath = [self fullPathForFile:@"project/foo.ccbproj"];
    for (NSString *packagePath in packages)
    {
        [_projectSettings addResourcePath:packagePath error:nil];
    }

    [self createFolders:packages];
}

@end
