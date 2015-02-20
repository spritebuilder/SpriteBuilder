//
//  Cocos2dUpdater_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 12.02.15.
//
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "Cocos2dUpdater.h"
#import "ProjectSettings.h"
#import "AppDelegate.h"
#import "FileSystemTestCase.h"
#import "Cocos2dUpdateDelegate.h"


@interface SBCocos2dUpdaterTestDelegate : NSObject <Cocos2dUpdateDelegate>

@property (nonatomic, copy) void (^updateSucceeededBlock)(void);
@property (nonatomic, copy) void (^updateFailedBlock)(NSError *error);
@property (nonatomic, copy) UpdateActions (^updateActionBlock)(NSString *text, NSString *versionProject, NSString *versionSB, NSString *backupPath);

@end

@implementation SBCocos2dUpdaterTestDelegate

- (void)updateSucceeded
{
    if (_updateSucceeededBlock)
    {
        _updateSucceeededBlock();
    }
}

- (void)updateFailedWithError:(NSError *)error
{
    if (_updateFailedBlock)
    {
        _updateFailedBlock(error);
    }
}

- (UpdateActions)updateAction:(NSString *)text projectsCocos2dVersion:(NSString *)projectsCocos2dVersion spriteBuildersCocos2dVersion:(NSString *)spriteBuildersCocos2dVersion backupPath:(NSString *)backupPath
{
    if (_updateActionBlock)
    {
        return _updateActionBlock(text, projectsCocos2dVersion, spriteBuildersCocos2dVersion, backupPath);
    }

    return UpdateActionNothingToDo;
}

@end


@interface Cocos2dUpdater_Tests : FileSystemTestCase

@property (nonatomic, strong) Cocos2dUpdater *cocos2dUpdater;
@property (nonatomic, strong) ProjectSettings *projectSettings;
@property (nonatomic, strong) SBCocos2dUpdaterTestDelegate *testDelegate;

@end


@implementation Cocos2dUpdater_Tests

- (void)setUp
{
    [super setUp];
    
    [self writeCocos2dVersionOfSpritebuilder:@"3.4" projectsVersion:@"3.3"];    

    self.projectSettings = [self createProjectSettingsFileWithName:@"baa.spritebuilder/foo"];

    self.testDelegate = [[SBCocos2dUpdaterTestDelegate alloc] init];

    self.cocos2dUpdater = [[Cocos2dUpdater alloc] initWithAppDelegate:nil projectSettings:_projectSettings];
    _cocos2dUpdater.delegate = _testDelegate;
};

- (void)testUpdateWithUserActionCancelUpdate
{
    __block BOOL updateActionBlockCalled = NO;
    [self setupUpdaterDelegate:UpdateActionNothingToDo failOnAction:NO failOnSuccess:YES failOnFailed:YES doBlockOnUpdateAction:^{
        updateActionBlockCalled = YES;
    }];

    [_cocos2dUpdater updateAndBypassIgnore:NO];

    [self assertContentsOfFilesEqual:@{
            @"baa.spritebuilder/Source/libs/cocos2d-iphone/VERSION" : @"3.3"
    }];

    XCTAssertTrue(updateActionBlockCalled);
};

- (void)testUpdateWithUserActionIgnoreThisVersion
{
    __block int updateActionBlockCalledCount = 0;
    [self setupUpdaterDelegate:UpdateActionIgnoreVersion failOnAction:NO failOnSuccess:YES failOnFailed:YES doBlockOnUpdateAction:^{
        updateActionBlockCalledCount++;
    }];

    [_cocos2dUpdater updateAndBypassIgnore:NO];
    [_cocos2dUpdater updateAndBypassIgnore:NO];

    XCTAssertEqual(updateActionBlockCalledCount, 1);
}

- (void)testUpdateWithUpdateToDateVersion
{
    // Need to redo this as versions are read upon instantiation of Cocos2dUpdater
    [self writeCocos2dVersionOfSpritebuilder:@"3.4" projectsVersion:@"3.4"];
    self.cocos2dUpdater = [[Cocos2dUpdater alloc] initWithAppDelegate:nil projectSettings:_projectSettings];
    _cocos2dUpdater.delegate = _testDelegate;

    [self setupUpdaterDelegate:UpdateActionIgnoreVersion failOnAction:YES failOnSuccess:YES failOnFailed:YES doBlockOnUpdateAction:nil];

    [_cocos2dUpdater updateAndBypassIgnore:NO];
}

- (void (^)(void))updateTestBlock
{
    return ^{
        [self removeProjectTemplateZipFile];
        [self copyTestingResource:@"Cocos2dupdater_test.zip" toRelPath:[self pathToProjectTemplateZipFile]];

        XCTestExpectation *updateExpectation = [self expectationWithDescription:@"cocos2d updater"];

        __block BOOL updateActionBlockCalled = NO;
        _testDelegate.updateActionBlock = ^UpdateActions(NSString *text, NSString *versionProject, NSString *versionSB, NSString *backupPath) {
            updateActionBlockCalled = YES;
            return UpdateActionUpdate;
        };

        __block BOOL successBlockCalled = NO;
        _testDelegate.updateSucceeededBlock = ^
        {
            successBlockCalled = YES;
            [updateExpectation fulfill];
        };

        _testDelegate.updateFailedBlock = ^(NSError *error)
        {
            XCTFail(@"Update failed");
            [updateExpectation fulfill];
        };

        [_cocos2dUpdater updateAndBypassIgnore:NO];

        [self waitForExpectationsWithTimeout:3 handler:^(NSError *error)
        {
            if (error != nil)
            {
                XCTFail(@"timeout error: %@", error);
            }
        }];

        XCTAssertTrue(successBlockCalled);
        XCTAssertTrue(updateActionBlockCalled);

        [self assertContentsOfFilesEqual:@{
                @"baa.spritebuilder/Source/libs/cocos2d-iphone/VERSION" : @"3.4.3"
        }];
    };
}

- (void)testUpdateFailingMissingProjectTemplateZip
{
    [self removeProjectTemplateZipFile];

    XCTestExpectation *updateExpectation = [self expectationWithDescription:@"cocos2d updater"];

    _testDelegate.updateActionBlock = ^UpdateActions(NSString *text, NSString *versionProject, NSString *versionSB, NSString *backupPath) {
        return UpdateActionUpdate;
    };

    _testDelegate.updateSucceeededBlock = ^
    {
        XCTFail(@"Update failed");
        [updateExpectation fulfill];
    };

    __block BOOL failedBlockCalled = NO;
    _testDelegate.updateFailedBlock = ^(NSError *error)
    {
        failedBlockCalled = YES;
        [updateExpectation fulfill];
    };

    [_cocos2dUpdater updateAndBypassIgnore:NO];

    [self waitForExpectationsWithTimeout:2 handler:^(NSError *error)
    {
        if (error != nil)
        {
            XCTFail(@"timeout error: %@", error);
        }
    }];

    XCTAssertTrue(failedBlockCalled);

    [self assertContentsOfFilesEqual:@{
            @"baa.spritebuilder/Source/libs/cocos2d-iphone/VERSION" : @"3.3"
    }];
}

- (void)testUpdateWithMissingProjectsVersionFile
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:[self fullPathForFile:@"baa.spritebuilder/Source/libs/cocos2d-iphone/VERSION"] error:nil];

    [self assertFileDoesNotExist:@"baa.spritebuilder/Source/libs/cocos2d-iphone/VERSION"];

    void (^updateTestBlock)() = [self updateTestBlock];
    updateTestBlock();
}

- (void)testUpdateWithKnownOlderVersion
{
    // The updater should not be interferred by the existence of this file
    [self createFilesWithContents:@{
            @"baa.spritebuilder/.gitmodules" : @"just some stuff in here"
    }];

    void (^updateTestBlock)() = [self updateTestBlock];
    updateTestBlock();
}

- (void)testUpdateWithBypassIgnoreFile
{
    __block int updateActionBlockCalledCount = 0;
    [self setupUpdaterDelegate:UpdateActionIgnoreVersion failOnAction:NO failOnSuccess:YES failOnFailed:YES doBlockOnUpdateAction:^{
        updateActionBlockCalledCount++;
    }];

    [_cocos2dUpdater updateAndBypassIgnore:NO];
    [_cocos2dUpdater updateAndBypassIgnore:YES];

    XCTAssertEqual(updateActionBlockCalledCount, 2);
}

- (void)testUpdateWithCocos2dAsSubmodule_oldIphoneGitRepo
{
    [self createFilesWithContents:@{
            @"baa.spritebuilder/.gitmodules" :
                   @"[submodule \"SpriteBuilder/libs/cocos2d-iphone\"]\n"
                    "\tpath = SpriteBuilder/libs/cocos2d-iphone\n"
                    "url=https://github.com/cocos2d/cocos2d-iphone.git"
    }];

    [self setupUpdaterDelegate:UpdateActionNothingToDo failOnAction:YES failOnSuccess:YES failOnFailed:YES doBlockOnUpdateAction:nil];

    [_cocos2dUpdater updateAndBypassIgnore:NO];
}

- (void)testUpdateWithCocos2dAsSubmodule_swiftRepo
{
    [self createFilesWithContents:@{
            @"baa.spritebuilder/.gitmodules" :
                   @"[submodule \"SpriteBuilder/libs/cocos2d-swift\"]\n"
                    "\tpath = SpriteBuilder/libs/cocos2d-iphone\n"
                    "url=https://github.com/cocos2d/cocos2d-swift.git"
    }];

    [self setupUpdaterDelegate:UpdateActionNothingToDo failOnAction:YES failOnSuccess:YES failOnFailed:YES doBlockOnUpdateAction:nil];

    [_cocos2dUpdater updateAndBypassIgnore:NO];
}


#pragma mark - helpers

- (NSString *)pathToProjectTemplateZipFile
{
    return [[NSBundle mainBundle] pathForResource:@"PROJECTNAME" ofType:@"zip" inDirectory:@"Generated"];
}

- (void)setupUpdaterDelegate:(UpdateActions)updateAction failOnAction:(BOOL)failOnAction failOnSuccess:(BOOL)failOnSuccess failOnFailed:(BOOL)failOnFailed doBlockOnUpdateAction:(void (^)(void))doBlock
{
    if (failOnAction)
    {
        _testDelegate.updateActionBlock = ^UpdateActions(NSString *text, NSString *versionProject, NSString *versionSB, NSString *backupPath) {
            if (doBlock)
            {
                doBlock();
            }
            XCTFail(@"The update action block should not be called");
            return updateAction;
        };
    }
    else
    {
        _testDelegate.updateActionBlock = ^UpdateActions(NSString *text, NSString *versionProject, NSString *versionSB, NSString *backupPath) {
            if (doBlock)
            {
                doBlock();
            }
            return updateAction;
        };
    }

    if (failOnSuccess)
    {
        _testDelegate.updateSucceeededBlock = ^{ XCTFail(@"The success block should not be called"); };
    }

    if (failOnFailed)
    {
        _testDelegate.updateFailedBlock = ^(NSError *error) { XCTFail(@"The fail block should not be called"); };
    }
}

- (void)writeCocos2dVersionOfSpritebuilder:(NSString *)sbVersion projectsVersion:(NSString *)projectsVersion
{
    NSString *versionFilePath = [[NSBundle mainBundle] pathForResource:@"cocos2d_version" ofType:@"txt" inDirectory:@"Generated"];

    [self createFilesWithContents:@{
            @"baa.spritebuilder/Source/libs/cocos2d-iphone/VERSION" : projectsVersion,
            versionFilePath : sbVersion
    }];
}

- (void)removeProjectTemplateZipFile
{
    NSString *zipFile = [self pathToProjectTemplateZipFile];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:zipFile error:nil];

    XCTAssertFalse([fileManager fileExistsAtPath:zipFile]);
};

@end
