//
//  ResourceManagerPreviewView_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 22.08.14.
//
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "ResourceManagerPreviewView.h"
#import "ProjectSettings.h"
#import "RMResource.h"
#import "ResourceTypes.h"
#import "FileSystemTestCase.h"
#import "ResourceManager.h"
#import "RMDirectory.h"
#import "FCFormatConverter.h"
#import "ResourcePropertyKeys.h"

@interface ResourceManagerPreviewView_Tests : FileSystemTestCase

@property (nonatomic, strong) ResourceManagerPreviewView *resourceManagerPreviewView;
@property (nonatomic, strong) ProjectSettings *projectSettings;
@property (nonatomic, strong) ResourceManager *resourceManager;
@property (nonatomic, strong) RMResource *resource;

@end


@implementation ResourceManagerPreviewView_Tests

- (void)setUp
{
    [super setUp];

    self.projectSettings = [[ProjectSettings alloc] init];
    _projectSettings.projectPath = [self fullPathForFile:@"project.spritebuilder/abc.ccbproj"];
    [_projectSettings addResourcePath:[self fullPathForFile:@"project.spritebuilder/Packages/foo.sbpack"] error:nil];
    [_projectSettings clearAllDirtyMarkers];

    self.resourceManagerPreviewView = [[ResourceManagerPreviewView alloc] init];
    _resourceManagerPreviewView.projectSettings = _projectSettings;

    self.resourceManager = [ResourceManager sharedManager];
    [_resourceManager setActiveDirectoriesWithFullReset:@[[self fullPathForFile:@"project.spritebuilder/Packages/foo.sbpack"]]];

    self.resource = [[RMResource alloc] initWithFilePath:[self fullPathForFile:@"project.spritebuilder/Packages/foo.sbpack/background.png"]];
}

- (void)testSettingResourceShouldNotMarkResourceAsDirty
{
    // Image
    _resource.type = kCCBResTypeImage;
    [_resourceManagerPreviewView setPreviewResource:_resource];
    XCTAssertFalse([_projectSettings isDirtyResource:_resource]);

    // SpriteSheet
    [self makeResourceASpriteSheet];
    [_resourceManagerPreviewView setPreviewResource:_resource];
    XCTAssertFalse([_projectSettings isDirtyResource:_resource]);

    // Audio file
    _resource.type = kCCBResTypeAudio;
    [_resourceManagerPreviewView setPreviewResource:_resource];
    XCTAssertFalse([_projectSettings isDirtyResource:_resource]);

    // CCBFile
    _resource.type = kCCBResTypeCCBFile;
    [_resourceManagerPreviewView setPreviewResource:_resource];
    XCTAssertFalse([_projectSettings isDirtyResource:_resource]);
}

- (void)testSettingValueShouldMarkResourceAsDiryForImages
{
    _resource.type = kCCBResTypeImage;
    [self setResourceProperties:@{
            @"tabletScale":@(1),
            @"format_ios":@(kFCImageFormatPVR_RGBA8888),
            @"format_ios_dither":@(YES),
            @"format_ios_compress":@(YES),
            @"format_android":@(kFCImageFormatPVR_RGBA8888),
            @"format_android_dither":@(YES),
            @"format_android_compress":@(YES)
    }];

    [_resourceManagerPreviewView setPreviewResource:_resource];

    [self setPropertiesIndividuallyAndAssertResourceIsDirty:@{
            @"tabletScale":@(2),
            @"format_ios":@(kFCImageFormatPVRTC_4BPP),
            @"format_ios_dither":@(NO),
            @"format_ios_compress":@(NO),
            @"format_android":@(kFCImageFormatPVRTC_4BPP),
            @"format_android_dither":@(NO),
            @"format_android_compress":@(NO)
    }];
}

- (void)testSettingValueShouldMarkResourceAsDiryForAudio
{
    _resource.type = kCCBResTypeAudio;
    [self setResourceProperties:@{
            RESOURCE_PROPERTY_IOS_SOUND : @(kFCSoundFormatMP4),
            RESOURCE_PROPERTY_IOS_SOUND_QUALITY : @(1),
            RESOURCE_PROPERTY_ANDROID_SOUND : @(2)
    }];

    [_resourceManagerPreviewView setPreviewResource:_resource];

    [self setPropertiesIndividuallyAndAssertResourceIsDirty:@{
            RESOURCE_PROPERTY_IOS_SOUND : @(kFCSoundFormatCAF),
            RESOURCE_PROPERTY_IOS_SOUND_QUALITY : @(4),
            RESOURCE_PROPERTY_ANDROID_SOUND : @(5)
    }];
}

- (void)testSettingValueShouldMarkResourceAsDiryForSpriteSheets
{
    [self makeResourceASpriteSheet];
    [self setResourceProperties:@{
            RESOURCE_PROPERTY_TRIM_SPRITES:@(YES)
    }];

    [_resourceManagerPreviewView setPreviewResource:_resource];

    [self setPropertiesIndividuallyAndAssertResourceIsDirty:@{
            RESOURCE_PROPERTY_TRIM_SPRITES:@(NO)
    }];
}

- (void)testSettingsValuesForImage
{
    _resource.type = kCCBResTypeImage;
    [self setResourceProperties:@{
            @"tabletScale":@(1),
            @"scaleFrom":@(1),
            @"format_ios":@(kFCImageFormatPVR_RGBA8888),
            @"format_ios_dither":@(YES),
            @"format_ios_compress":@(YES),
            @"format_android":@(kFCImageFormatPVR_RGBA8888),
            @"format_android_dither":@(YES),
            @"format_android_compress":@(YES)
    }];

    [_resourceManagerPreviewView setPreviewResource:_resource];

    [self setPropertiesIndividuallyAndAssertPropertyIsOfGivenValue:@{
            // @"tabletScale":@(2), // is not testable this way atm: 2 is a default value atm
            @"scaleFrom" : @(2),
            @"format_ios" : @(kFCImageFormatPVRTC_4BPP),
            @"format_ios_dither" : @(NO),
            @"format_ios_compress" : @(NO),
            @"format_android" : @(kFCImageFormatPVRTC_4BPP),
            @"format_android_dither" : @(NO),
            @"format_android_compress" : @(NO)
    } isAudio:NO];
}

- (void)testSettingsValuesForAudio
{
    _resource.type = kCCBResTypeAudio;
    [self setResourceProperties:@{
            RESOURCE_PROPERTY_IOS_SOUND : @(kFCSoundFormatMP4),
            RESOURCE_PROPERTY_IOS_SOUND_QUALITY : @(1),
            // Yes this is illegal app wise but we need a value here that will be different from the set one
            RESOURCE_PROPERTY_ANDROID_SOUND : @(kFCSoundFormatCAF),
            RESOURCE_PROPERTY_ANDROID_SOUND_QUALITY : @(1)
    }];

    [_resourceManagerPreviewView setPreviewResource:_resource];

    [self setPropertiesIndividuallyAndAssertPropertyIsOfGivenValue:@{
            RESOURCE_PROPERTY_IOS_SOUND : @(kFCSoundFormatCAF),
            RESOURCE_PROPERTY_IOS_SOUND_QUALITY : @(4),
            RESOURCE_PROPERTY_ANDROID_SOUND : @(kFCSoundFormatOGG),
            RESOURCE_PROPERTY_ANDROID_SOUND_QUALITY : @(6)
    } isAudio:YES];
}


- (void)testSettingsValuesForSpriteSheet
{
    [self makeResourceASpriteSheet];
    [self setResourceProperties:@{
            RESOURCE_PROPERTY_TRIM_SPRITES : @(NO),
    }];

    [_resourceManagerPreviewView setPreviewResource:_resource];

    [self setPropertiesIndividuallyAndAssertPropertyIsOfGivenValue:@{
            RESOURCE_PROPERTY_TRIM_SPRITES : @(YES),
    }                                                      isAudio:NO];
}

- (void)setResourceProperties:(NSDictionary *)properties
{
    for (NSString *key in properties)
    {
        id value = properties[key];

        [_projectSettings setProperty:value forResource:_resource andKey:key];
    }
    [_projectSettings clearAllDirtyMarkers];
}

- (void)setPropertiesIndividuallyAndAssertResourceIsDirty:(NSDictionary *)properties
{
    for (NSString *key in properties)
    {
        id value = properties[key];

        [_projectSettings clearAllDirtyMarkers];
        [_resourceManagerPreviewView setValue:value forKey:key];
        XCTAssertTrue([_projectSettings isDirtyResource:_resource], @"Resource not dirty for key \"%@\", value \"%@\"", key, value);
    }
}

- (void)setPropertiesIndividuallyAndAssertPropertyIsOfGivenValue:(NSDictionary *)properties isAudio:(BOOL)isAudio
{
    for (NSString *key in properties)
    {
        id newValue = properties[key];

        [_projectSettings clearAllDirtyMarkers];
        [_resourceManagerPreviewView setValue:newValue forKey:key];

        id oldValue = [[_projectSettings propertyForResource:_resource andKey:key] copy];

        // Scalar values that test for false are removed from the properties, like NO or 0
        // BUT not for sounds, there's a inconsistency here.
        // As long as NO converts to 0 everything should be fine here...
        if ([newValue intValue] || isAudio)
        {
            XCTAssertTrue([oldValue isEqual:newValue], @"Setting resource property \"%@\" is not equal. Old value \"%@\", new value \"%@\"", key, oldValue, newValue);
        }
        else
        {
            XCTAssertNil(oldValue);
        }
    }
}

- (void)makeResourceASpriteSheet
{
    id mock = [OCMockObject mockForClass:[RMDirectory class]];
    [[[mock stub] andReturnValue:@YES] isDynamicSpriteSheet];

    _resource.type = kCCBResTypeDirectory;
    _resource.data = mock;
}

@end
