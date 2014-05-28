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

- (void)testAddResourcePath
{
    NSError *error;
    XCTAssertTrue([_projectSettings addResourcePath:@"/project/resourcepath1" error:&error]);
    XCTAssertNil(error);
    // Default init will add a default value to resourcePaths, see testStandardInitialization
    XCTAssertEqual(_projectSettings.resourcePaths.count, 2);
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

    XCTAssertEqual(_projectSettings.resourcePaths.count, 2);
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
    XCTAssertEqual(error.code, SBResourcePathNotInProjectError);
}

@end
