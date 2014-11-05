//
//  ResourcePropertiesMigrator_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 25.08.14.
//
//

#import <XCTest/XCTest.h>
#import "ProjectSettings.h"
#import "ResourcePropertiesMigrator.h"
#import "FileSystemTestCase.h"
#import "ResourcePropertyKeys.h"

@interface ResourcePropertiesMigrator_Tests : FileSystemTestCase

@property (nonatomic, strong) ProjectSettings *projectSettings;
@property (nonatomic, strong) ResourcePropertiesMigrator *migrator;

@end

@implementation ResourcePropertiesMigrator_Tests

- (void)setUp
{
    [super setUp];

    self.projectSettings = [[ProjectSettings alloc] init];
    _projectSettings.projectPath = [self fullPathForFile:@"foo.spritebuilder/foo.ccbproj"];

    self.migrator = [[ResourcePropertiesMigrator alloc] initWithProjectSettings:self.projectSettings];
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

    [_migrator migrate];

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

@end
