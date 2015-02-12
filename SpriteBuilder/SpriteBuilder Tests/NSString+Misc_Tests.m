//
//  NSString+Misc_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 11.02.15.
//
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "FileSystemTestCase.h"
#import "NSString+Misc.h"

@interface NSString_Misc_Tests : FileSystemTestCase

@end

@implementation NSString_Misc_Tests

- (void)testAvailabeFileNameWithRollingNumber
{
    [self createEmptyFiles:@[@"file.png"]];

    NSString *result = [[self fullPathForFile:@"file.png"] availabeFileNameWithRollingNumberAndExtraExtension:nil];
    XCTAssertEqualObjects(result, [self fullPathForFile:@"file.png.0"]);
}

- (void)testAvailabeFileNameWithRollingNumberAndPostfixAndPostfix_noBackupFiles
{
    [self createEmptyFiles:@[@"file.png"]];

    NSString *result = [[self fullPathForFile:@"file.png"] availabeFileNameWithRollingNumberAndExtraExtension:@"backup"];

    XCTAssertEqualObjects(result, [self fullPathForFile:@"file.png.backup.0"]);
}

- (void)testAvailabeFileNameWithRollingNumberAndPostfixAndPostfix_backupFilePresent
{
    [self createEmptyFiles:@[
            @"file.png",
            @"file.png.backup",
    ]];

    NSString *result = [[self fullPathForFile:@"file.png"] availabeFileNameWithRollingNumberAndExtraExtension:@"backup"];

    XCTAssertEqualObjects(result, [self fullPathForFile:@"file.png.backup.0"]);
}

- (void)testAvailabeFileNameWithRollingNumberAndPostfixAndPostfix_fileDoesNotExist
{
    XCTAssertNil([[self fullPathForFile:@"does_not_exist.png"] availabeFileNameWithRollingNumberAndExtraExtension:@"backup"]);
}

- (void)testAvailabeFileNameWithRollingNumberAndPostfixAndPostfix_manyBackupFilePresent
{
    [self createEmptyFiles:@[
            @"file.png",
            @"file.png.backup",
            @"file.png.backup.0",
            @"file.png.backup.3",
    ]];

    NSString *result = [[self fullPathForFile:@"file.png"] availabeFileNameWithRollingNumberAndExtraExtension:@"backup"];

    XCTAssertEqualObjects(result, [self fullPathForFile:@"file.png.backup.4"]);
}

@end
