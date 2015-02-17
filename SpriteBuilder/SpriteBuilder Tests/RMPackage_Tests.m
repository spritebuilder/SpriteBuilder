//
//  RMPackage_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 11.06.14.
//
//

#import <XCTest/XCTest.h>

#import "RMPackage.h"
#import "MiscConstants.h"
#import "NSString+Packages.h"

@interface RMPackage_Tests : XCTestCase

@end

@implementation RMPackage_Tests

- (void)testNameProperty
{
    RMPackage *package = [[RMPackage alloc] init];
    package.dirPath = [@"/project/packages/foo" stringByAppendingPackageSuffix];

    XCTAssertEqualObjects(package.name, @"foo");
}

- (void)testNamePropertyWithDoubleSuffix
{
    RMPackage *package = [[RMPackage alloc] init];
    package.dirPath = [[@"/project/packages/foo" stringByAppendingPackageSuffix] stringByAppendingPackageSuffix];

    XCTAssertEqualObjects(package.name, [@"foo" stringByAppendingPackageSuffix]);
}

@end
