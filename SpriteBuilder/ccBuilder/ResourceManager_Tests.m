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

@interface ResourceManager_Tests : FileSystemTestCase

@property (nonatomic, strong) ResourceManager *resourceManager;

@end


@implementation ResourceManager_Tests

- (void)setUp
{
    [super setUp];

    self.resourceManager = [ResourceManager sharedManager];
}

- (void)testResourceForRelativePath
{
    RMResource *image = [[RMResource alloc] initWithFilePath:[self fullPathForFile:@"project/Packages/package1.sbpack/image.png"]];
    [_resourceManager setActiveDirectoriesWithFullReset:@[
            [self fullPathForFile:@"project/Packages/package1.sbpack"],
    ]];

    RMDirectory *activeDirectory = [_resourceManager activeDirectoryForPath:[self fullPathForFile:@"project/Packages/package1.sbpack"]];
    [activeDirectory.any addObject:image];
    [activeDirectory.images addObject:image];

    RMResource *resource = [[ResourceManager sharedManager] resourceForRelPath:@"image.png"];

    XCTAssertTrue([image isEqual:resource]);
}

@end
