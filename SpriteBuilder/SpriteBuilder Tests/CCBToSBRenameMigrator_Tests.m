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

@interface CCBToSBRenameMigrator_Tests : FileSystemTestCase

@end

@implementation CCBToSBRenameMigrator_Tests

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

    CCBToSBRenameMigrator *migrator = [[CCBToSBRenameMigrator alloc] initWithDirPath:[self fullPathForFile:@"foo.spritebuilder/packages/foo.sbpack"]];

    XCTAssertTrue([migrator isMigrationRequired]);

    NSError *error;
    XCTAssertTrue([migrator migrateWithError:&error]);
    XCTAssertNil(error);

    [self assertFilesDoNotExistRelativeToDirectory:@"foo.spritebuilder/packages" filesPaths:@[
        @"foo.sbpack/scenes/level1/renameonly.ccb",
        @"foo.sbpack/scenes/somcenestedfolder/level1/whoa.ccb",
        @"foo.spritebuilder/packages/baa.sbpack/docs/universe001/milkyway/sol/earth/ocean/marianatrench/treasurechest.ccb"
    ]];

    [self assertContentsOfFilesEqual:@{
        @"foo.spritebuilder/packages/foo.sbpack/scenes/level1/renameonly.sb" : ccbDefaultContents,
        @"foo.spritebuilder/packages/foo.sbpack/scenes/level1/donothing.pdf" : @"nothing in here",
        @"foo.spritebuilder/packages/foo.sbpack/scenes/somcenestedfolder/level1/whoa.sb" : [self migratedCCBContents],
        @"foo.spritebuilder/packages/baa.sbpack/docs/universe001/milkyway/sol/earth/ocean/marianatrench/not_in_dir_path_of_migrator.ccb" : [self ccBContentsThatCanBeMigrated],
    }];
};

- (void)testHtmlInfoText
{
    CCBToSBRenameMigrator *migrator = [[CCBToSBRenameMigrator alloc] initWithDirPath:[self fullPathForFile:@"foo.spritebuilder/packages/foo.sbpack"]];
    XCTAssertNotNil([migrator htmlInfoText]);
}

- (void)testRollback
{
    [self createFilesWithContents:@{
        @"scenes/level1/renameonly.ccb" : @{@"asd" : @100},
        @"scenes/baa.ccb" : @{@"key" : @"door"},
        @"scenes/somcenestedfolder/level1/whoa.ccb" : [self ccBContentsThatCanBeMigrated],
    }];

    CCBToSBRenameMigrator *migrator = [[CCBToSBRenameMigrator alloc] initWithDirPath:[self fullPathForFile:@"scenes"]];

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

    CCBToSBRenameMigrator *migrator = [[CCBToSBRenameMigrator alloc] initWithDirPath:[self fullPathForFile:@"foo.spritebuilder/packages/foo.sbpack"]];

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
