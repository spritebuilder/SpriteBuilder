//
//  NSString+Publishing_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 02.07.14.
//
//

#import <XCTest/XCTest.h>
#import "FileSystemTestCase.h"
#import "NSString+Publishing.h"

@interface NSString_Publishing_Tests : FileSystemTestCase

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation NSString_Publishing_Tests

- (void)setUp
{
    [super setUp];

    self.dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setDateFormat:@"dd/MM/yy HH:mm:ss"];
    [_dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
}

- (void)testLatestModifiedDateOfPath
{
    [self createEmptyFiles:@[@"abc/123/text.txt", @"abc/456/baa/translation.txt"]];

    NSDate *date = [NSDate dateWithTimeIntervalSince1970:0];
    [self setModificationTime:date forFiles:@[
            @"abc",
            @"abc/123",
            @"abc/123/text.txt",
            @"abc/456",
            @"abc/456/baa",
            @"abc/456/baa/translation.txt"]];

    [self setModificationTime:[_dateFormatter dateFromString:@"31/12/01 18:00:00"]
                     forFiles:@[@"abc/123"]];

    [self setModificationTime:[_dateFormatter dateFromString:@"31/12/01 17:59:59"]
                     forFiles:@[@"abc/123/text.txt"]];

    [self setModificationTime:[_dateFormatter dateFromString:@"31/12/01 13:00:00"]
                     forFiles:@[@"abc/456/baa/translation.txt"]];

    NSString *fullPath = [self fullPathForFile:@"abc"];
    NSDate *latestModifiedDate = [fullPath latestModifiedDateOfPathIgnoringDirs:NO];
    NSDate *expectedDate = [_dateFormatter dateFromString:@"31/12/01 18:00:00"];
    XCTAssertTrue([latestModifiedDate isEqualToDate:expectedDate], @"Date is %@, expected %@ for file %@", latestModifiedDate, expectedDate, fullPath);
}

- (void)testLatestModifiedDateOfPathIgnoringDirectories
{
    [self createEmptyFiles:@[@"abc/123/456/text.txt"]];

    NSDate *date = [NSDate dateWithTimeIntervalSince1970:0];
    [self setModificationTime:date forFiles:@[
            @"abc",
            @"abc/123",
            @"abc/123/456",
            @"abc/123/456/text.txt"]];

    [self setModificationTime:[_dateFormatter dateFromString:@"31/12/01 22:00:00"]
                     forFiles:@[@"abc/123"]];

    [self setModificationTime:[_dateFormatter dateFromString:@"31/12/01 21:59:59"]
                     forFiles:@[@"abc/123/456/text.txt"]];

    [self setModificationTime:[_dateFormatter dateFromString:@"31/12/01 22:59:59"]
                     forFiles:@[@"abc/123/456"]];

    NSString *fullPath = [self fullPathForFile:@"abc"];
    NSDate *latestModifiedDate = [fullPath latestModifiedDateOfPathIgnoringDirs:YES];
    NSDate *expectedDate = [_dateFormatter dateFromString:@"31/12/01 21:59:59"];
    XCTAssertTrue([latestModifiedDate isEqualToDate:expectedDate], @"Date is %@, expected %@ for file %@", latestModifiedDate, expectedDate, fullPath);
}

@end
