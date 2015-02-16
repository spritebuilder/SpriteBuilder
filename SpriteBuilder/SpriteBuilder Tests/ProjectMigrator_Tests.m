//
//  ProjectMigrator_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 25.08.14.
//
//

#import <XCTest/XCTest.h>
#import "ProjectSettings.h"
#import "ProjectSettingsMigrator.h"
#import "FileSystemTestCase.h"
#import "ResourcePropertyKeys.h"

@interface ProjectMigrator_Tests : FileSystemTestCase

@property (nonatomic, strong) ProjectSettings *projectSettings;
@property (nonatomic, strong) ProjectSettingsMigrator *migrator;

@end

@implementation ProjectMigrator_Tests

- (void)setUp
{
    [super setUp];

    self.projectSettings = [self createProjectSettingsFileWithName:@"foo.spritebuilder/foo.ccbproj"];

    self.migrator = [[ProjectSettingsMigrator alloc] initWithProjectSettings:_projectSettings];
}

- (void)testMigration
{
    [_projectSettings setProperty:@1 forRelPath:@"flowers" andKey:RESOURCE_PROPERTY_LEGACY_KEEP_SPRITES_UNTRIMMED];
    [_projectSettings setProperty:@YES forRelPath:@"flowers" andKey:RESOURCE_PROPERTY_IS_SMARTSHEET];
    [_projectSettings markAsDirtyRelPath:@"flowers"];

    [_projectSettings setProperty:@YES forRelPath:@"rocks" andKey:RESOURCE_PROPERTY_IS_SMARTSHEET];
    [_projectSettings clearDirtyMarkerOfRelPath:@"rocks"];

    [_projectSettings setProperty:@3 forRelPath:@"background.png" andKey:RESOURCE_PROPERTY_IOS_IMAGE_FORMAT];
    [_projectSettings clearDirtyMarkerOfRelPath:@"background.png"];

    NSError *error;
    XCTAssertTrue([_migrator migrateWithError:&error]);
    XCTAssertNil(error);

    XCTAssertFalse([_projectSettings propertyForRelPath:@"flowers" andKey:RESOURCE_PROPERTY_LEGACY_KEEP_SPRITES_UNTRIMMED]);
    XCTAssertFalse([_projectSettings propertyForRelPath:@"flowers" andKey:RESOURCE_PROPERTY_TRIM_SPRITES]);
    XCTAssertTrue([_projectSettings isDirtyRelPath:@"flowers"]);

    XCTAssertFalse([_projectSettings propertyForRelPath:@"rocks" andKey:RESOURCE_PROPERTY_LEGACY_KEEP_SPRITES_UNTRIMMED]);
    XCTAssertFalse([_projectSettings propertyForRelPath:@"rocks" andKey:RESOURCE_PROPERTY_TRIM_SPRITES]);
    XCTAssertFalse([_projectSettings isDirtyRelPath:@"rocks"]);

    XCTAssertFalse([_projectSettings propertyForRelPath:@"background.png" andKey:RESOURCE_PROPERTY_LEGACY_KEEP_SPRITES_UNTRIMMED]);
    XCTAssertFalse([_projectSettings propertyForRelPath:@"background.png" andKey:RESOURCE_PROPERTY_TRIM_SPRITES]);
    XCTAssertFalse([_projectSettings isDirtyRelPath:@"background.png"]);
}

- (void)testRollback
{
    [_projectSettings setProperty:@1 forRelPath:@"flowers" andKey:RESOURCE_PROPERTY_LEGACY_KEEP_SPRITES_UNTRIMMED];
    [_projectSettings setProperty:@YES forRelPath:@"flowers" andKey:RESOURCE_PROPERTY_IS_SMARTSHEET];
    [_projectSettings markAsDirtyRelPath:@"flowers"];
    [_projectSettings store];

    NSString *originalPrjSettingsFile = [NSString stringWithContentsOfFile:_projectSettings.projectPath encoding:NSUTF8StringEncoding error:nil];

    NSError *error;
    XCTAssertTrue([_migrator migrateWithError:&error]);
    XCTAssertNil(error);

    [_projectSettings store];

    [_migrator rollback];

    NSString *newPrjSettingsFile = [NSString stringWithContentsOfFile:_projectSettings.projectPath encoding:NSUTF8StringEncoding error:nil];

    BOOL equal = [originalPrjSettingsFile isEqualToString:newPrjSettingsFile];
    XCTAssertTrue(equal);
    if (!equal)
    {
        NSLog(@"Diff:");
        [self diff:originalPrjSettingsFile stringB:newPrjSettingsFile];
    }
}



#pragma mark - helpers

- (void)diff:(NSString *)stringA stringB:(NSString *)stringB
{
    NSTask *task = [[NSTask alloc] init];
    [task setCurrentDirectoryPath:NSTemporaryDirectory()];
    [task setLaunchPath:@"/bin/bash"];

    NSArray *args = @[@"-c", [NSString stringWithFormat:@"/usr/bin/diff <(echo \"%@\") <(echo \"%@\")", stringA, stringB]];
    [task setArguments:args];

    @try
    {
        [task launch];
        [task waitUntilExit];
    }
    @catch (NSException *exception)
    {
        NSLog(@"[COCO2D-UPDATER] [ERROR] unzipping failed: %@", exception);
    }
}


@end
