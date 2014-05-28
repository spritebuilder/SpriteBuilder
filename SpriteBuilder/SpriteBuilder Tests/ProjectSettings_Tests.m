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
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testStandardInitialization
{
    XCTAssertEqual(_projectSettings.resourcePaths.count, 1);
    id firstResourcePath = _projectSettings.resourcePaths[0];
    XCTAssertEqualObjects([firstResourcePath objectForKey:@"path"], @"Resources");
}

- (void)testRemoveResourcePath
{
    _projectSettings.projectPath = @"/project/ccbuttonwooga.ccbproj";
    [_projectSettings.resourcePaths addObject:@{@"path" : @"test"}];

    NSError *error;
    XCTAssertTrue([_projectSettings removeResourcePath:@"/project/test" error:&error]);
    // Default init will add a default value to resourcePaths, see testStandardInitialization
    XCTAssertEqual(_projectSettings.resourcePaths.count, 1);
    XCTAssertNil(error);
}

- (void)testRemoveNonExistingResourcePath
{
    _projectSettings.projectPath = @"/project/ccbuttonwooga.ccbproj";

    NSError *error;
    XCTAssertFalse([_projectSettings removeResourcePath:@"/project/test" error:&error]);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, SBResourcePathNotInProject);
}

@end
