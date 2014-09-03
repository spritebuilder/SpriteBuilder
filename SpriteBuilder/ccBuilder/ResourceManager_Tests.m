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

@end
