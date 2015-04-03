//
//  CCBToSBRenameMigrator_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 20.02.15.
//
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "FileSystemTestCase.h"
#import "CCBToSBRenameMigrator.h"
#import "CCBDocument.h"
#import "CCBDictionaryReader.h"
#import "MigratorData.h"

@interface CCBToSBRenameMigrator_Tests : FileSystemTestCase

@end

@implementation CCBToSBRenameMigrator_Tests

- (void)testRenameWithFilePathPointer
{
    [self createFilesWithContents:@{
            @"document.ccb" : @{@"nodeGraph" : @{}, @"fileVersion" : @4}
    }];

    NSString *filePath = [self fullPathForFile:@"document.ccb"];

    MigratorData *migratorData = [[MigratorData alloc] init];
    CCBToSBRenameMigrator *migrator = [[CCBToSBRenameMigrator alloc] initWithFilePath:filePath  migratorData:migratorData];

    XCTAssertTrue([migrator isMigrationRequired]);

    NSError *error;
    XCTAssertTrue([migrator migrateWithError:&error]);
    XCTAssertNil(error);

    XCTAssertEqualObjects(migratorData.renamedFiles[filePath], [self fullPathForFile:@"document.sb"]);

    [self assertFileExists:@"document.sb"];
    [self assertFileDoesNotExist:@"document.ccb"];
}

- (void)testRenameCCBFilesToSBWithFilePathGiven
{
    [self createFilesWithContents:@{ @"foo.spritebuilder/foo.ccb" : @{@"nodeGraph" : @{}, @"fileVersion" : @4} }];

    MigratorData *migratorData = [[MigratorData alloc] init];
    CCBToSBRenameMigrator *migrator = [[CCBToSBRenameMigrator alloc] initWithFilePath:[self fullPathForFile:@"foo.spritebuilder/foo.ccb"]
                                                                         migratorData:migratorData];

    XCTAssertTrue([migrator isMigrationRequired]);

    NSError *error;
    XCTAssertTrue([migrator migrateWithError:&error]);
    XCTAssertNil(error);

    [self assertFileExists:@"foo.spritebuilder/foo.sb"];
    [self assertFileDoesNotExist:@"foo.spritebuilder/foo.ccb"];
}

- (void)testRenameCCBFilesToSB
{
    NSDictionary *ccbDefaultContents = @{
        @"nodeGraph" : @{},
        @"fileVersion" : @4
    };

    [self createFilesWithContents:@{
        @"foo.spritebuilder/packages/foo.sbpack/scenes/level1/renameonly.ccb" : ccbDefaultContents,
        @"foo.spritebuilder/packages/foo.sbpack/scenes/level1/donothing.pdf" : @"nothing in here",
        @"foo.spritebuilder/packages/foo.sbpack/scenes/somcenestedfolder/level1/whoa.ccb" : [self ccBContentsThatCanBeMigrated],
        @"foo.spritebuilder/packages/baa.sbpack/docs/universe001/milkyway/sol/earth/ocean/marianatrench/not_in_dir_path_of_migrator.ccb" : [self ccBContentsThatCanBeMigrated],
    }];

    MigratorData *migratorData = [[MigratorData alloc] init];
    CCBToSBRenameMigrator *migrator = [[CCBToSBRenameMigrator alloc] initWithFilePath:[self fullPathForFile:@"foo.spritebuilder/packages/foo.sbpack"] migratorData:migratorData];

    XCTAssertTrue([migrator isMigrationRequired]);

    NSError *error;
    XCTAssertTrue([migrator migrateWithError:&error]);
    XCTAssertNil(error);

    NSString *org1 = @"foo.spritebuilder/packages/foo.sbpack/scenes/level1/renameonly.ccb";
    NSString *org2 = @"foo.spritebuilder/packages/foo.sbpack/scenes/somcenestedfolder/level1/whoa.ccb";

    NSString *new1 = @"foo.spritebuilder/packages/foo.sbpack/scenes/level1/renameonly.sb";
    NSString *new2 = @"foo.spritebuilder/packages/foo.sbpack/scenes/somcenestedfolder/level1/whoa.sb";

    [self assertFileDoesNotExist:org1];
    [self assertFileDoesNotExist:org2];

    [self assertFileExists:new1];
    [self assertFileExists:new2];

    [self assertFilesExistRelativeToDirectory:@"foo.spritebuilder/packages" filesPaths:@[
       @"foo.sbpack/scenes/level1/donothing.pdf",
       @"baa.sbpack/docs/universe001/milkyway/sol/earth/ocean/marianatrench/not_in_dir_path_of_migrator.ccb"
    ]];

    // NOTE Super hack: /var/... paths can be special links to /private/var and FileSystemTestCase is creating files within
    // the temp folder which usually resides in /var. The tested method is using a NSDirectoryEnumerator which actually
    // resolves these special links resulting in different paths string wise. DAMN!
    for (NSString *key in [migratorData.renamedFiles copy])
    {
        if ([key hasPrefix:@"/private"])
        {
            NSString *newKey = [key stringByReplacingCharactersInRange:NSMakeRange(0, 8) withString:@""];
            NSString *newVal = [migratorData.renamedFiles[key] stringByReplacingCharactersInRange:NSMakeRange(0, 8) withString:@""];
            migratorData.renamedFiles[newKey] = newVal;
            [migratorData.renamedFiles removeObjectForKey:key];
        }
    }

    XCTAssertEqualObjects(migratorData.renamedFiles[[self fullPathForFile:org1]], [self fullPathForFile:new1]);
    XCTAssertEqualObjects(migratorData.renamedFiles[[self fullPathForFile:org2]], [self fullPathForFile:new2]);
};

- (void)testRollback
{
    [self createFilesWithContents:@{
        @"scenes/level1/renameonly.ccb" : @{@"asd" : @100},
        @"scenes/baa.ccb" : @{@"key" : @"door"},
        @"scenes/somcenestedfolder/level1/whoa.ccb" : [self ccBContentsThatCanBeMigrated],
    }];

    MigratorData *migratorData = [[MigratorData alloc] init];
    CCBToSBRenameMigrator *migrator = [[CCBToSBRenameMigrator alloc] initWithFilePath:[self fullPathForFile:@"scenes"] migratorData:migratorData];

    XCTAssertTrue([migrator isMigrationRequired]);

    NSError *error;
    XCTAssertTrue([migrator migrateWithError:&error]);
    XCTAssertNil(error);

    [migrator rollback];

    [self assertContentsOfFilesEqual:@{
        @"scenes/level1/renameonly.ccb" : @{@"asd" : @100},
        @"scenes/baa.ccb" : @{@"key" : @"door"},
        @"scenes/somcenestedfolder/level1/whoa.ccb" : [self ccBContentsThatCanBeMigrated],
    }];
}

- (void)testMigrationNotRequired
{
    [self createFilesWithContents:@{
        @"scenes/level1/renameonly.sb" : @{@"asd" : @100},
        @"scenes/baa.sb" : @{@"key" : @"door"},
        @"scenes/somcenestedfolder/level1/whoa.sb" : [self ccBContentsThatCanBeMigrated],
    }];

    MigratorData *migratorData = [[MigratorData alloc] init];
    CCBToSBRenameMigrator *migrator = [[CCBToSBRenameMigrator alloc] initWithFilePath:[self fullPathForFile:@"foo.spritebuilder/packages/foo.sbpack"] migratorData:migratorData];

    XCTAssertFalse([migrator isMigrationRequired]);

    NSError *error;
    XCTAssertTrue([migrator migrateWithError:&error]);
    XCTAssertNil(error);
}

- (NSDictionary *)ccBContentsThatCanBeMigrated
{
    return @{
        @"nodeGraph" : @{
            @"properties" : @[],
            @"children" : @[
                @{
                    @"properties" : @[
                        @{
                            @"name" : @"ccbFile",
                            @"type" : @"CCBFile",
                            @"value" : @"foo.ccb"
                        }
                    ]
                },
                @{
                    @"properties" : @[],
                    @"children" : @[
                        @{
                            @"properties" : @[
                                @{
                                    @"name" : @"ccbFile",
                                    @"type" : @"CCBFile",
                                    @"value" : @"baa.ccb"
                                }
                            ]
                        }
                    ]
                }
            ]
            },
        @"fileVersion" : @5
    };
}

- (NSDictionary *)migratedCCBContents
{
    return @{
        @"nodeGraph" : @{
            @"properties" : @[],
            @"children" : @[
                @{
                    @"properties" : @[
                        @{
                            @"name" : @"sbFile",
                            @"type" : @"SBFile",
                            @"value" : @"foo.sb"
                        }
                    ]
                },
                @{
                    @"properties" : @[],
                    @"children" : @[
                        @{
                            @"properties" : @[
                                @{
                                    @"name" : @"sbFile",
                                    @"type" : @"SBFile",
                                    @"value" : @"baa.sb"
                                }
                            ]
                        }
                    ]
                }
            ]
            },
        @"fileVersion" : @5
    };
}

@end
