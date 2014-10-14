//
//  RMResource_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 02.09.14.
//
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "RMResource.h"
#import "ResourceTypes.h"
#import "RMDirectory.h"
#import "FileSystemTestCase.h"
#import "ProjectSettings+Packages.h"

@interface RMResource_Tests : FileSystemTestCase

@property (nonatomic, strong) RMResource *resource;

@end


@implementation RMResource_Tests

- (void)setUp
{
    [super setUp];

    self.resource = [[RMResource alloc] init];
}

- (void)testIsSpriteSheet
{
    _resource.type = kCCBResTypeDirectory;
    id mock = [OCMockObject mockForClass:[RMDirectory class]];
    [[[mock stub] andReturnValue:@YES] isDynamicSpriteSheet];
    _resource.data = mock;

    XCTAssertTrue([_resource isSpriteSheet]);

    _resource.type = kCCBResTypeAnimation;
    XCTAssertFalse([_resource isSpriteSheet]);

    _resource.type = kCCBResTypeDirectory;
    _resource.data = nil;
    XCTAssertFalse([_resource isSpriteSheet]);
}

@end
