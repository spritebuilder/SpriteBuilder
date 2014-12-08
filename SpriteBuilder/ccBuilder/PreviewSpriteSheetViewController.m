//
//  PreviewSpriteSheetViewController.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 26.08.14.
//
//

#import "PreviewBaseViewController.h"
#import "PreviewSpriteSheetViewController.h"
#import "RMResource.h"
#import "ProjectSettings.h"
#import "MiscConstants.h"
#import "CCBImageView.h"
#import "ImageFormatAndPropertiesHelper.h"
#import "ResourcePropertyKeys.h"


@implementation PreviewSpriteSheetViewController

- (void)setPreviewedResource:(RMResource *)previewedResource projectSettings:(ProjectSettings *)projectSettings
{
    self.projectSettings = projectSettings;
    self.previewedResource = previewedResource;

    [self populateInitialValues];
}

- (void)populateInitialValues
{
    __weak PreviewSpriteSheetViewController *weakSelf = self;
    [self setInitialValues:^{

        weakSelf.format_ios = [[weakSelf.projectSettings propertyForResource:weakSelf.previewedResource andKey:RESOURCE_PROPERTY_IOS_IMAGE_FORMAT] intValue];
        weakSelf.format_ios_dither = [[weakSelf.projectSettings propertyForResource:weakSelf.previewedResource andKey:RESOURCE_PROPERTY_IOS_IMAGE_DITHER] boolValue];
        weakSelf.format_ios_compress = [[weakSelf.projectSettings propertyForResource:weakSelf.previewedResource andKey:RESOURCE_PROPERTY_IOS_IMAGE_COMPRESS] boolValue];
        weakSelf.format_ios_dither_enabled = [ImageFormatAndPropertiesHelper supportsDither:(kFCImageFormat) weakSelf.format_ios osType:kCCBPublisherOSTypeIOS];
        weakSelf.format_ios_compress_enabled = [ImageFormatAndPropertiesHelper supportsCompress:(kFCImageFormat) weakSelf.format_ios osType:kCCBPublisherOSTypeIOS];

        weakSelf.format_android = [[weakSelf.projectSettings propertyForResource:weakSelf.previewedResource andKey:RESOURCE_PROPERTY_ANDROID_IMAGE_FORMAT] intValue];
        weakSelf.format_android_dither = [[weakSelf.projectSettings propertyForResource:weakSelf.previewedResource andKey:RESOURCE_PROPERTY_ANDROID_IMAGE_DITHER] boolValue];
        weakSelf.format_android_compress = [[weakSelf.projectSettings propertyForResource:weakSelf.previewedResource andKey:RESOURCE_PROPERTY_ANDROID_IMAGE_COMPRESS]
                                                          boolValue];
        weakSelf.format_android_dither_enabled = [ImageFormatAndPropertiesHelper supportsDither:(kFCImageFormat) weakSelf.format_android osType:kCCBPublisherOSTypeAndroid];
        weakSelf.format_android_compress_enabled = [ImageFormatAndPropertiesHelper supportsCompress:(kFCImageFormat) weakSelf.format_android osType:kCCBPublisherOSTypeAndroid];

        weakSelf.trimSprites = [[weakSelf.projectSettings propertyForResource:weakSelf.previewedResource andKey:RESOURCE_PROPERTY_TRIM_SPRITES] boolValue];
    }];

    NSString *imgPreviewPath = [_previewedResource.filePath stringByAppendingPathExtension:PNG_PREVIEW_IMAGE_SUFFIX];
    NSImage *img = [[NSImage alloc] initWithContentsOfFile:imgPreviewPath];
    if (!img)
    {
        img = [NSImage imageNamed:@"ui-nopreview.png"];
    }

    [_previewSpriteSheet setImage:img];
}

- (void) setFormat_ios:(int)format_ios
{
   _format_ios = format_ios;
   [self setValue:@(format_ios) withName:RESOURCE_PROPERTY_IOS_IMAGE_FORMAT isAudio:NO];

   self.format_ios_dither_enabled = [ImageFormatAndPropertiesHelper supportsDither:(kFCImageFormat)_format_ios osType:kCCBPublisherOSTypeIOS];
   self.format_ios_compress_enabled = [ImageFormatAndPropertiesHelper supportsCompress:(kFCImageFormat)_format_ios osType:kCCBPublisherOSTypeIOS];
}

- (void) setFormat_android:(int)format_android
{
   _format_android = format_android;
   [self setValue:@(format_android) withName:RESOURCE_PROPERTY_ANDROID_IMAGE_FORMAT isAudio:NO];

   self.format_android_dither_enabled = [ImageFormatAndPropertiesHelper supportsDither:(kFCImageFormat)_format_android osType:kCCBPublisherOSTypeAndroid];
   self.format_android_compress_enabled = [ImageFormatAndPropertiesHelper supportsCompress:(kFCImageFormat)_format_android osType:kCCBPublisherOSTypeAndroid];
}

- (void) setFormat_ios_dither:(BOOL)format_ios_dither
{
   _format_ios_dither = format_ios_dither;
   [self setValue:@(format_ios_dither) withName:RESOURCE_PROPERTY_IOS_IMAGE_DITHER isAudio:NO];
}

- (void) setFormat_android_dither:(BOOL)format_android_dither
{
   _format_android_dither = format_android_dither;
   [self setValue:@(format_android_dither) withName:RESOURCE_PROPERTY_ANDROID_IMAGE_DITHER isAudio:NO];
}

- (void) setFormat_ios_compress:(BOOL)format_ios_compress
{
   _format_ios_compress = format_ios_compress;
   [self setValue:@(format_ios_compress) withName:RESOURCE_PROPERTY_IOS_IMAGE_COMPRESS isAudio:NO];
}

- (void) setFormat_android_compress:(BOOL)format_android_compress
{
   _format_android_compress = format_android_compress;
   [self setValue:@(format_android_compress) withName:RESOURCE_PROPERTY_ANDROID_IMAGE_COMPRESS isAudio:NO];
}

- (void) setTrimSprites:(BOOL) trimSprites
{
    _trimSprites = trimSprites;
    [self setValue:@(trimSprites) withName:RESOURCE_PROPERTY_TRIM_SPRITES isAudio:NO];
}

@end
