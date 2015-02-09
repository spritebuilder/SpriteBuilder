//
//  ResourceManagerPreviewView_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 22.08.14.
//
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "ProjectSettings.h"
#import "RMResource.h"
#import "ResourceTypes.h"
#import "FileSystemTestCase.h"
#import "ResourceManager.h"
#import "RMDirectory.h"
#import "FCFormatConverter.h"
#import "ResourcePropertyKeys.h"
#import "PreviewContainerViewController.h"
#import "PreviewImageViewController.h"
#import "PreviewAudioViewController.h"
#import "PreviewSpriteSheetViewController.h"

@interface PreviewView_Tests : FileSystemTestCase

@property (nonatomic, strong) ProjectSettings *projectSettings;
@property (nonatomic, strong) ResourceManager *resourceManager;
@property (nonatomic, strong) RMResource *resource;
@property (nonatomic, strong) PreviewImageViewController *previewImageViewController;
@property (nonatomic, strong) PreviewAudioViewController *previewAudioViewController;
@property (nonatomic, strong) PreviewSpriteSheetViewController *previewSpriteSheetViewController;

@end


@implementation PreviewView_Tests

- (void)setUp
{
    [super setUp];

    self.projectSettings = [[ProjectSettings alloc] init];
    _projectSettings.projectPath = [self fullPathForFile:@"project.spritebuilder/abc.ccbproj"];
    [_projectSettings addResourcePath:[self fullPathForFile:@"project.spritebuilder/Packages/foo.sbpack"] error:nil];
    [_projectSettings clearAllDirtyMarkers];

    self.resourceManager = [ResourceManager sharedManager];
    [_resourceManager setActiveDirectoriesWithFullReset:@[[self fullPathForFile:@"project.spritebuilder/Packages/foo.sbpack"]]];

    self.resource = [[RMResource alloc] initWithFilePath:[self fullPathForFile:@"project.spritebuilder/Packages/foo.sbpack/background.png"]];
    
    self.previewImageViewController = [[PreviewImageViewController alloc] initWithNibName:@"PreviewImageView" bundle:nil];
    self.previewAudioViewController = [[PreviewAudioViewController alloc] initWithNibName:@"PreviewAudioView" bundle:nil];
    self.previewSpriteSheetViewController = [[PreviewSpriteSheetViewController alloc] initWithNibName:@"PreviewSpriteSheetView" bundle:nil];
}

- (void)testSettingResourceShouldNotMarkResourceAsDirty
{
    _resource.type = kCCBResTypeImage;
    [_previewImageViewController setPreviewedResource:_resource projectSettings:_projectSettings];
    XCTAssertFalse([_projectSettings isDirtyResource:_resource]);

    [self makeResourceASpriteSheet];
    [_previewSpriteSheetViewController setPreviewedResource:_resource projectSettings:_projectSettings];
    XCTAssertFalse([_projectSettings isDirtyResource:_resource]);

    _resource.type = kCCBResTypeAudio;
    [_previewAudioViewController setPreviewedResource:_resource projectSettings:_projectSettings];
    XCTAssertFalse([_projectSettings isDirtyResource:_resource]);
}

- (void)testSettingValueShouldMarkResourceAsDiryForImages
{
    _resource.type = kCCBResTypeImage;
    [self setResourceProperties:@{
            RESOURCE_PROPERTY_IOS_IMAGE_FORMAT : @(kFCImageFormatPVR_RGBA8888),
            RESOURCE_PROPERTY_IOS_IMAGE_DITHER : @(YES),
            RESOURCE_PROPERTY_IOS_IMAGE_COMPRESS : @(YES),
            RESOURCE_PROPERTY_ANDROID_IMAGE_FORMAT : @(kFCImageFormatPVR_RGBA8888),
            RESOURCE_PROPERTY_ANDROID_IMAGE_DITHER : @(YES),
            RESOURCE_PROPERTY_ANDROID_IMAGE_COMPRESS : @(YES)
    }];

    [_previewImageViewController setPreviewedResource:_resource projectSettings:_projectSettings];

    [self setPropertiesIndividuallyAndAssertResourceIsDirtyViewController:_previewImageViewController
                                                               properties:@{
            RESOURCE_PROPERTY_IOS_IMAGE_FORMAT : @(kFCImageFormatPVRTC_4BPP),
            RESOURCE_PROPERTY_IOS_IMAGE_DITHER : @(NO),
            RESOURCE_PROPERTY_IOS_IMAGE_COMPRESS : @(NO),
            RESOURCE_PROPERTY_ANDROID_IMAGE_FORMAT : @(kFCImageFormatPVRTC_4BPP),
            RESOURCE_PROPERTY_ANDROID_IMAGE_DITHER : @(NO),
            RESOURCE_PROPERTY_ANDROID_IMAGE_COMPRESS : @(NO)
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

    [_previewAudioViewController setPreviewedResource:_resource
                                      projectSettings:_projectSettings];

    [self setPropertiesIndividuallyAndAssertResourceIsDirtyViewController:_previewAudioViewController
                                                               properties:@{
            RESOURCE_PROPERTY_IOS_SOUND : @(kFCSoundFormatCAF),
            RESOURCE_PROPERTY_IOS_SOUND_QUALITY : @(4),
            RESOURCE_PROPERTY_ANDROID_SOUND : @(5)
    }];
}


- (void)testSettingValueShouldMarkResourceAsDiryForSpriteSheets
{
    [self makeResourceASpriteSheet];
    [self setResourceProperties:@{
            RESOURCE_PROPERTY_TRIM_SPRITES:@(YES),
            RESOURCE_PROPERTY_IOS_IMAGE_FORMAT : @(kFCImageFormatPVR_RGBA8888),
            RESOURCE_PROPERTY_IOS_IMAGE_DITHER : @(YES),
            RESOURCE_PROPERTY_IOS_IMAGE_COMPRESS : @(YES),
            RESOURCE_PROPERTY_ANDROID_IMAGE_FORMAT : @(kFCImageFormatPVR_RGBA8888),
            RESOURCE_PROPERTY_ANDROID_IMAGE_DITHER : @(YES),
            RESOURCE_PROPERTY_ANDROID_IMAGE_COMPRESS : @(YES)
    }];

    [_previewSpriteSheetViewController setPreviewedResource:_resource
                                            projectSettings:_projectSettings];

    [self setPropertiesIndividuallyAndAssertResourceIsDirtyViewController:_previewSpriteSheetViewController
                                                               properties:@{
            RESOURCE_PROPERTY_TRIM_SPRITES:@(NO),
            RESOURCE_PROPERTY_IOS_IMAGE_FORMAT : @(kFCImageFormatPVRTC_4BPP),
            RESOURCE_PROPERTY_IOS_IMAGE_DITHER : @(NO),
            RESOURCE_PROPERTY_IOS_IMAGE_COMPRESS : @(NO),
            RESOURCE_PROPERTY_ANDROID_IMAGE_FORMAT : @(kFCImageFormatPVRTC_4BPP),
            RESOURCE_PROPERTY_ANDROID_IMAGE_DITHER : @(NO),
            RESOURCE_PROPERTY_ANDROID_IMAGE_COMPRESS : @(NO)
    }];
}

- (void)testSettingsValuesForImage
{
    _resource.type = kCCBResTypeImage;
    [self setResourceProperties:@{
            RESOURCE_PROPERTY_IMAGE_USEUISCALE:@(YES),
            RESOURCE_PROPERTY_IMAGE_SCALE_FROM:@(1),
            RESOURCE_PROPERTY_IOS_IMAGE_FORMAT:@(kFCImageFormatPVR_RGBA8888),
            RESOURCE_PROPERTY_IOS_IMAGE_DITHER:@(YES),
            RESOURCE_PROPERTY_IOS_IMAGE_COMPRESS:@(YES),
            RESOURCE_PROPERTY_ANDROID_IMAGE_FORMAT:@(kFCImageFormatPVR_RGBA8888),
            RESOURCE_PROPERTY_ANDROID_IMAGE_DITHER:@(YES),
            RESOURCE_PROPERTY_ANDROID_IMAGE_COMPRESS:@(YES)
    }];

    [_previewImageViewController setPreviewedResource:_resource projectSettings:_projectSettings];

    [self assertPropertiesAreSetToViewController:_previewImageViewController
                                         isAudio:NO
                                      properties:@{
        RESOURCE_PROPERTY_IMAGE_USEUISCALE : @(YES),
        RESOURCE_PROPERTY_IMAGE_SCALE_FROM : @(2),
        RESOURCE_PROPERTY_IOS_IMAGE_FORMAT : @(kFCImageFormatPVRTC_4BPP),
        RESOURCE_PROPERTY_IOS_IMAGE_DITHER : @(NO),
        RESOURCE_PROPERTY_IOS_IMAGE_COMPRESS : @(NO),
        RESOURCE_PROPERTY_ANDROID_IMAGE_FORMAT : @(kFCImageFormatPVRTC_4BPP),
        RESOURCE_PROPERTY_ANDROID_IMAGE_DITHER : @(NO),
        RESOURCE_PROPERTY_ANDROID_IMAGE_COMPRESS : @(NO)
    }];
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

    [_previewAudioViewController setPreviewedResource:_resource projectSettings:_projectSettings];

    [self assertPropertiesAreSetToViewController:_previewAudioViewController
                                         isAudio:YES
                                      properties:@{
            RESOURCE_PROPERTY_IOS_SOUND : @(kFCSoundFormatCAF),
            RESOURCE_PROPERTY_IOS_SOUND_QUALITY : @(4),
            RESOURCE_PROPERTY_ANDROID_SOUND : @(kFCSoundFormatOGG),
            RESOURCE_PROPERTY_ANDROID_SOUND_QUALITY : @(6)
    }];
}

- (void)testSettingsValuesForSpriteSheet
{
    [self makeResourceASpriteSheet];
    [self setResourceProperties:@{
            RESOURCE_PROPERTY_TRIM_SPRITES : @(NO),
            RESOURCE_PROPERTY_IOS_IMAGE_FORMAT:@(kFCImageFormatPVR_RGBA8888),
            RESOURCE_PROPERTY_IOS_IMAGE_DITHER:@(YES),
            RESOURCE_PROPERTY_IOS_IMAGE_COMPRESS:@(YES),
            RESOURCE_PROPERTY_ANDROID_IMAGE_FORMAT:@(kFCImageFormatPVR_RGBA8888),
            RESOURCE_PROPERTY_ANDROID_IMAGE_DITHER:@(YES),
            RESOURCE_PROPERTY_ANDROID_IMAGE_COMPRESS:@(YES)
    }];

    [_previewSpriteSheetViewController setPreviewedResource:_resource projectSettings:_projectSettings];

    [self assertPropertiesAreSetToViewController:_previewSpriteSheetViewController
                                         isAudio:NO
                                      properties:@{
            RESOURCE_PROPERTY_TRIM_SPRITES : @(YES),
            RESOURCE_PROPERTY_IOS_IMAGE_FORMAT : @(kFCImageFormatPVRTC_4BPP),
            RESOURCE_PROPERTY_IOS_IMAGE_DITHER : @(NO),
            RESOURCE_PROPERTY_IOS_IMAGE_COMPRESS : @(NO),
            RESOURCE_PROPERTY_ANDROID_IMAGE_FORMAT : @(kFCImageFormatPVRTC_4BPP),
            RESOURCE_PROPERTY_ANDROID_IMAGE_DITHER : @(NO),
            RESOURCE_PROPERTY_ANDROID_IMAGE_COMPRESS : @(NO)
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

- (void)setPropertiesIndividuallyAndAssertResourceIsDirtyViewController:(NSViewController *)viewController
                                                             properties:(NSDictionary *)properties
{
    for (NSString *key in properties)
    {
        id value = properties[key];

        [_projectSettings clearAllDirtyMarkers];
        [viewController setValue:value forKey:key];
        XCTAssertTrue([_projectSettings isDirtyResource:_resource], @"Resource not dirty for key \"%@\", value \"%@\"", key, value);
    }
}

- (void)assertPropertiesAreSetToViewController:(NSViewController *)viewController
                                       isAudio:(BOOL)isAudio
                                    properties:(NSDictionary *)properties
{
    for (NSString *key in properties)
    {
        id newValue = properties[key];

        [_projectSettings clearAllDirtyMarkers];
        [viewController setValue:newValue forKey:key];

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
