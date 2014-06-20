//
//  FeatureToggle_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 28.05.14.
//
//

#import <XCTest/XCTest.h>
#import <objc/runtime.h>
#import "FeatureToggle.h"



@interface FeatureToggleTestSubclass : FeatureToggle

@property (nonatomic) BOOL foo;

@end


@implementation FeatureToggleTestSubclass

@end



@interface FeatureToggle_Tests : XCTestCase

@end


@implementation FeatureToggle_Tests

- (void)testLoadingFeaturesWithDictionary
{
    NSString *featureName = @"foo";
    NSDictionary *featuresDict = @{featureName : @(1)};

    FeatureToggleTestSubclass *featureToggle = [[FeatureToggleTestSubclass alloc] init];

    [featureToggle loadFeaturesWithDictionary:featuresDict];

    @try
    {
        XCTAssertTrue([[featureToggle valueForKey:featureName] boolValue]);
    }
    @catch (NSException *e)
    {
        XCTFail(@"Failed to set feature with name %@", featureName);
    }
}

@end
