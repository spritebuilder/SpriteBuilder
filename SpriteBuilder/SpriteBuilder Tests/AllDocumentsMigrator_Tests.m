//
//  AllDocumentsMigrator_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 19.02.15.
//
//

#import <XCTest/XCTest.h>
#import "AllDocumentsMigrator.h"
#import "FileSystemTestCase.h"
#import "CCBDictionaryKeys.h"
#import "ProjectSettings.h"

@interface AllDocumentsMigrator_Tests : FileSystemTestCase

@property (nonatomic, strong) AllDocumentsMigrator *migrator;

@end


@implementation AllDocumentsMigrator_Tests

- (void)testMigrationOfSomeDeeplyNestedDocuments
{
    [self createFolders:@[
            @"foo.spritebuilder/packages/foo.sbpack/folder/deeper/deepest",
            @"foo.spritebuilder/packages/baa.sbpack/scenes"
    ]];

    NSString *path1 = [self fullPathForFile:@"foo.spritebuilder/packages/foo.sbpack/folder/deeper/deepest/abc.ccb"];
    NSString *path2 = [self fullPathForFile:@"foo.spritebuilder/packages/foo.sbpack/folder/deeper/uptodate.sb"];
    NSString *path3 = [self fullPathForFile:@"foo.spritebuilder/packages/baa.sbpack/scenes/xyz.ccb"];
    NSString *path4 = [self fullPathForFile:@"donotmigrate.ccb"];

    [@{CCB_DICTIONARY_KEY_FILEVERSION : @4, CCB_DICTIONARY_KEY_NODEGRAPH : @{}}  writeToFile:path1  atomically:YES];
    [@{CCB_DICTIONARY_KEY_FILEVERSION : @5, CCB_DICTIONARY_KEY_NODEGRAPH : @{}}  writeToFile:path2  atomically:YES];
    [@{CCB_DICTIONARY_KEY_FILEVERSION : @4, CCB_DICTIONARY_KEY_NODEGRAPH : @{}}  writeToFile:path3  atomically:YES];
    [@{CCB_DICTIONARY_KEY_FILEVERSION : @1, CCB_DICTIONARY_KEY_NODEGRAPH : @{}}  writeToFile:path4  atomically:YES];

    AllDocumentsMigrator *migrator = [[AllDocumentsMigrator alloc] initWithDirPath:[self fullPathForFile:@"foo.spritebuilder"] toVersion:5];
    XCTAssertTrue([migrator isMigrationRequired]);
    
    NSError *error;
    XCTAssertTrue([migrator migrateWithError:&error]);
    XCTAssertNil(error);

    NSDictionary *file1 = [NSDictionary dictionaryWithContentsOfFile:path1];
    XCTAssertEqualObjects(file1[CCB_DICTIONARY_KEY_FILEVERSION], @5);

    NSDictionary *file2 = [NSDictionary dictionaryWithContentsOfFile:path2];
    XCTAssertEqualObjects(file2[CCB_DICTIONARY_KEY_FILEVERSION], @5);

    NSDictionary *file3 = [NSDictionary dictionaryWithContentsOfFile:path3];
    XCTAssertEqualObjects(file3[CCB_DICTIONARY_KEY_FILEVERSION], @5);

    NSDictionary *file4 = [NSDictionary dictionaryWithContentsOfFile:path4];
    XCTAssertEqualObjects(file4[CCB_DICTIONARY_KEY_FILEVERSION], @1);
}

- (void)testRollback
{
    [self createFolders:@[@"foo.spritebuilder/packages/foo.sbpack/folder"]];

    NSString *path1 = [self fullPathForFile:@"foo.spritebuilder/packages/foo.sbpack/abc.ccb"];
    NSDictionary *dict1 = @{CCB_DICTIONARY_KEY_FILEVERSION : @4, CCB_DICTIONARY_KEY_NODEGRAPH : @{}};
    [dict1 writeToFile:path1  atomically:YES];

    NSString *path2 = [self fullPathForFile:@"foo.spritebuilder/packages/foo.sbpack/folder/def.sb"];
    NSDictionary *dict2 = @{CCB_DICTIONARY_KEY_FILEVERSION : @3, CCB_DICTIONARY_KEY_NODEGRAPH : @{}};
    [dict2 writeToFile:path2  atomically:YES];

    AllDocumentsMigrator *migrator = [[AllDocumentsMigrator alloc] initWithDirPath:[self fullPathForFile:@"foo.spritebuilder"] toVersion:5];
    XCTAssertTrue([migrator isMigrationRequired]);

    NSError *error;
    XCTAssertTrue([migrator migrateWithError:&error]);
    XCTAssertNil(error);

    [migrator rollback];

    [self assertEqualObjectsWithDiff:dict1 objectB:[NSDictionary dictionaryWithContentsOfFile:path1]];
    [self assertEqualObjectsWithDiff:dict2 objectB:[NSDictionary dictionaryWithContentsOfFile:path2]];
}

- (void)testMigrationNotRequired
{
    [self createFolders:@[@"foo.spritebuilder/packages/foo.sbpack"]];

    NSString *path1 = [self fullPathForFile:@"foo.spritebuilder/packages/foo.sbpack/abc.ccb"];
    NSDictionary *dict1 = @{CCB_DICTIONARY_KEY_FILEVERSION : @5, CCB_DICTIONARY_KEY_NODEGRAPH : @{}};
    [dict1 writeToFile:path1  atomically:YES];

    AllDocumentsMigrator *migrator = [[AllDocumentsMigrator alloc] initWithDirPath:[self fullPathForFile:@"foo.spritebuilder"] toVersion:5];
    XCTAssertFalse([migrator isMigrationRequired]);

    NSError *error;
    XCTAssertTrue([migrator migrateWithError:&error]);
    XCTAssertNil(error);

    [self assertEqualObjectsWithDiff:dict1 objectB:[NSDictionary dictionaryWithContentsOfFile:path1]];
}

@end
