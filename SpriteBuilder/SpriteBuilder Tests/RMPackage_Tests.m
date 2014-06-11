//
//  RMPackage_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 11.06.14.
//
//

#import <XCTest/XCTest.h>
#import "SBAssserts.h"

#import "RMPackage.h"
#import "MiscConstants.h"

@interface RMPackage_Tests : XCTestCase

@end

@implementation RMPackage_Tests

- (void)testNameProperty
{
    RMPackage *package = [[RMPackage alloc] init];
    package.dirPath = [NSString stringWithFormat:@"/project/packages/foo.%@", PACKAGE_NAME_SUFFIX];

    SBAssertStringsEqual(package.name, @"foo");
}

- (void)testNamePropertyWithDoubleSuffix
{
    RMPackage *package = [[RMPackage alloc] init];
    package.dirPath = [NSString stringWithFormat:@"/project/packages/foo.%@.%@", PACKAGE_NAME_SUFFIX, PACKAGE_NAME_SUFFIX];

    // XCTAssertTrue([package.name isEqualToString:@"foo.sbpack"], @"Package name is %@", package.name);
    SBAssertStringsEqual(package.name, @"foo.sbpack");
}

@end
