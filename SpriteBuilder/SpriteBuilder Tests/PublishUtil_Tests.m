//
//  PublishUtil_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 16.10.14.
//
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "FileSystemTestCase.h"
#import "ProjectSettings.h"
#import "PublishUtil.h"

@interface PublishUtil_Tests : FileSystemTestCase

@property (nonatomic, strong) ProjectSettings *projectSettings;

@end


@implementation PublishUtil_Tests

- (void)setUp
{
    [super setUp];

    NSString *relPathToProjectFile = @"baa/projects/foo.spritebuilder/foo.ccbproj";
    [self createEmptyFiles:@[relPathToProjectFile]];

    self.projectSettings = [[ProjectSettings alloc] init];
    _projectSettings.projectPath = [self fullPathForFile:relPathToProjectFile];
}

- (void)testDirectoryContrainingProjectDir
{
    // ../.. translates to /TESTFOLDER/baa/projects
    PublishDirectoryDeletionRisk result = [PublishUtil riskForPublishDirectoryBeingDeletedUponPublish:@".."
                                                                                      projectSettings:_projectSettings];
    XCTAssertEqual(PublishDirectoryDeletionRiskDirectoryContainingProject, result);
}

- (void)testProjectfolderItselfAtRisk
{
    // ../.. translates to /TESTFOLDER/baa/projects/foo.spritebuilder
    PublishDirectoryDeletionRisk result = [PublishUtil riskForPublishDirectoryBeingDeletedUponPublish:@"."
                                                                                      projectSettings:_projectSettings];
    XCTAssertEqual(PublishDirectoryDeletionRiskDirectoryContainingProject, result);
}

- (void)testNonEmptyDirectory
{
    // Test non empty folder inside of project dir
    NSString *relPathNonEmptyFolder = [_projectSettings.projectPathDir stringByAppendingPathComponent:@"nonempty"];
    [self createEmptyFiles:@[[relPathNonEmptyFolder stringByAppendingPathComponent:@"foo.text"]]];

    PublishDirectoryDeletionRisk result = [PublishUtil riskForPublishDirectoryBeingDeletedUponPublish:relPathNonEmptyFolder
                                                                                      projectSettings:_projectSettings];
    XCTAssertEqual(PublishDirectoryDeletionRiskNonEmptyDirectory, result);


    // Test non empty folder outside of project dir
    [self createEmptyFiles:@[[[self fullPathForFile:@"temp"] stringByAppendingPathComponent:@"foo.text"]]];
    // ../../temp translates to /TESTFOLDER/temp
    PublishDirectoryDeletionRisk result2 = [PublishUtil riskForPublishDirectoryBeingDeletedUponPublish:@"../../../temp"
                                                                                       projectSettings:_projectSettings];
    XCTAssertEqual(PublishDirectoryDeletionRiskNonEmptyDirectory, result2);
}

- (void)testEmptyFolder
{
    // Test empty folder inside of project dir
    NSString *relPathEmptyFolder = [_projectSettings.projectPathDir stringByAppendingPathComponent:@"empty"];
    [self createFolders:@[relPathEmptyFolder]];

    PublishDirectoryDeletionRisk result = [PublishUtil riskForPublishDirectoryBeingDeletedUponPublish:relPathEmptyFolder
                                                                                      projectSettings:_projectSettings];

    XCTAssertEqual(PublishDirectoryDeletionRiskSafe, result);

    // Test empty folder outside of project dir
    [self createFolders:@[@"temp"]];
    PublishDirectoryDeletionRisk result2 = [PublishUtil riskForPublishDirectoryBeingDeletedUponPublish:@"../../../temp"
                                                                                       projectSettings:_projectSettings];
    XCTAssertEqual(PublishDirectoryDeletionRiskSafe, result2);
}

@end
