//
//  ResourceManager+Publishing_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 28.07.14.
//
//

#import <XCTest/XCTest.h>
#import "ResourceManager.h"
#import "FileSystemTestCase.h"
#import "RMPackage.h"
#import "ResourceManager+Publishing.h"
#import "PackagePublishSettings.h"
#import "SBAssserts.h"

@interface ResourceManager_Publishing_Tests : FileSystemTestCase

@property (nonatomic, strong) ResourceManager *resourceManager;

@end


@implementation ResourceManager_Publishing_Tests

- (void)setUp
{
    [super setUp];

    // self.resourceManager = [ResourceManager sharedManager];

    self.resourceManager = [[ResourceManager alloc] init];

    // Note: Do not invoke this after creating directories, else weird things will happen
    // I guess due to path watchers being added
    [_resourceManager setActiveDirectoriesWithFullReset:@[
            [self fullPathForFile:@"foo.spritebuilder/Packages/package1.sbpack"],
            [self fullPathForFile:@"foo.spritebuilder/Packages/package2.sbpack"],
            [self fullPathForFile:@"foo.spritebuilder/resources"]
    ]];

    [self createFolders:@[
            @"foo.spritebuilder/Packages/package1.sbpack",
            @"foo.spritebuilder/Packages/package2.sbpack",
            @"foo.spritebuilder/resources"]];

    RMPackage *package1 = [[RMPackage alloc] init];
    package1.dirPath = [self fullPathForFile:@"foo.spritebuilder/Packages/package1.sbpack"];
    PackagePublishSettings *packagePublishSettings1 = [[PackagePublishSettings alloc] initWithPackage:package1];
    [packagePublishSettings1 store];

    RMPackage *package2 = [[RMPackage alloc] init];
    package2.dirPath = [self fullPathForFile:@"foo.spritebuilder/Packages/package2.sbpack"];
    PackagePublishSettings *packagePublishSettings2 = [[PackagePublishSettings alloc] initWithPackage:package2];
    [packagePublishSettings2 store];
}

- (void)testLoadAllPackageSettings
{
    NSArray *packageSettings = [_resourceManager loadAllPackageSettings];

    XCTAssertEqual([packageSettings count], 2);

    for (PackagePublishSettings *setting in packageSettings)
    {
        XCTAssertTrue([setting isKindOfClass:[PackagePublishSettings class]]);
    }
}

@end
