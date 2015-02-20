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

- (void)testAllFilesInDirWithFilterBlock
{
    [self createEmptyFiles:@[
            @"foo/baa/yo.png",
            @"yellow/green/red/color.png",
            @"yellow/blue/morecolors.png",
    ]];

    NSArray *matches = [[self fullPathForFile:@"yellow"] allFilesInDirWithFilterBlock:^BOOL(NSURL *fileURL)
    {
        NSString *filename;
        [fileURL getResourceValue:&filename forKey:NSURLNameKey error:nil];

        NSNumber *symbolicLink;
        [fileURL getResourceValue:&symbolicLink forKey:NSURLIsSymbolicLinkKey error:nil];

        return [[fileURL relativeString] hasSuffix:@"png"];
    }];

    // NOTE Super hack: /var/... paths can be special links to /private/var and FileSystemTestCase is creating files within
    // the temp folder which usually resides in /var. The tested method is using a NSDirectoryEnumerator which actually
    // resolves these special links resulting in different paths string wise. DAMN!
    NSMutableArray *matchesCopy = [NSMutableArray array];
    for (NSString *string in matches)
    {
        if ([string hasPrefix:@"/private"])
        {
            [matchesCopy addObject:[string stringByReplacingCharactersInRange:NSMakeRange(0, 8) withString:@""]];
        }
        else
        {
            [matchesCopy addObject:string];
        }
    }

    XCTAssertTrue([matchesCopy containsObject:[self fullPathForFile:@"yellow/green/red/color.png"]]);
    XCTAssertTrue([matchesCopy containsObject:[self fullPathForFile:@"yellow/blue/morecolors.png"]]);
    XCTAssertFalse([matchesCopy containsObject:[self fullPathForFile:@"foo/baa/yo.png"]]);
}

- (void)testReplaceExtension
{
    XCTAssertEqualObjects([@"/foo/baa.png" replaceExtension:@"jpg"], @"/foo/baa.jpg");

    XCTAssertEqualObjects([@"new.pdf.ps" replaceExtension:@"doc"], @"new.pdf.doc");

    XCTAssertEqualObjects([@"secrets.pdf.pdf" replaceExtension:@"doc"], @"secrets.pdf.doc");

    XCTAssertEqualObjects([@"truths.ps.pdf" replaceExtension:@"pdf"], @"truths.ps.pdf");

    XCTAssertEqualObjects([@"foo_ps" replaceExtension:@"no"], @"foo_ps");
}

@end
