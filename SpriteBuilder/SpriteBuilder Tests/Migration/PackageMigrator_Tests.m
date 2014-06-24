//
//  PackageMigrator_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 24.06.14.
//
//

#import <XCTest/XCTest.h>
#import "PackageMigrator.h"
#import "ProjectSettings.h"
#import "FileSystemTestCase.h"

@interface PackageMigrator_Tests : FileSystemTestCase

@end

@implementation PackageMigrator_Tests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testExample
{
    [self createFolders:@[@"SpriteBuilder Resources"]];
    [self createProjectSettingsFileWithName:@"migrationtest"];

    [self createEmptyFiles:@[
            @"SpriteBuilder Resources/asset.png",
            @"SpriteBuilder Resources/scene.ccb"]];

    XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}

@end
