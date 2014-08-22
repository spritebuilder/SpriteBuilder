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
    [_projectSettings addResourcePath:[self fullPathForFile:@"project.spritebuilder/Packages/package1.sbpack"] error:nil];
    [_projectSettings clearAllDirtyMarkers];

    self.resourceManagerPreviewView = [[ResourceManagerPreviewView alloc] init];
    _resourceManagerPreviewView.projectSettings = _projectSettings;

    self.resourceManager = [ResourceManager sharedManager];
    [_resourceManager setActiveDirectoriesWithFullReset:@[[self fullPathForFile:@"Packages/foo.sbpack"]]];

    self.resource = [[RMResource alloc] initWithFilePath:[self fullPathForFile:@"Packages/foo.sbpack/background.png"]];
}

- (void)testSettingResourceShouldNotMarkResourceAsDirty
{
    // Image
    _resource.type = kCCBResTypeImage;
    [_resourceManagerPreviewView setPreviewResource:_resource];
    XCTAssertFalse([_projectSettings isDirtyResource:_resource]);

    // SpriteSheet
    id mock = [OCMockObject mockForClass:[RMDirectory class]];
    [[[mock stub] andReturnValue:@YES] isDynamicSpriteSheet];

    _resource.type = kCCBResTypeDirectory;
    _resource.data  = mock;
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
            @"format_ios":@(kFCImageFormatPVR_RGBA8888),
            @"format_ios_dither":@(YES),
            @"format_ios_compress":@(YES),
            @"format_android":@(kFCImageFormatPVR_RGBA8888),
            @"format_android_dither":@(YES),
            @"format_android_compress":@(YES)
    }];

    [_resourceManagerPreviewView setPreviewResource:_resource];

    [self setPropertiesIndividuallyAndAssertResourceIsDirty:@{
            @"format_ios":@(kFCImageFormatPVRTC_4BPP),
            @"format_ios_dither":@(NO),
            @"format_ios_compress":@(NO),
            @"format_android":@(kFCImageFormatPVRTC_4BPP),
            @"format_android_dither":@(NO),
            @"format_android_compress":@(NO)
    }];
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


@end
