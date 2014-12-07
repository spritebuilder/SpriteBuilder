//
//  PreviewAudioViewController.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 26.08.14.
//
//

#import "PreviewAudioViewController.h"
#import "RMResource.h"
#import "MiscConstants.h"
#import "ResourcePropertyKeys.h"
#import "ProjectSettings.h"
#import "AudioPlayerViewController.h"

@interface PreviewAudioViewController ()

@property (nonatomic, strong) AudioPlayerViewController *audioPlayerViewController;

@end


@implementation PreviewAudioViewController

- (void)setPreviewedResource:(RMResource *)previewedResource projectSettings:(ProjectSettings *)projectSettings
{
    self.projectSettings = projectSettings;
    self.previewedResource = previewedResource;

    [self initializeAudioController];

    [self initializeIcon];

    [self populateInitialValues];
}

- (void)initializeAudioController
{
    self.audioPlayerViewController = [[AudioPlayerViewController alloc] initWithNibName:@"AudioPlayerView" bundle:nil];

    _audioPlayerViewController.view.frame = CGRectMake(0, 0, _audioControllerContainer.frame.size.width, _audioControllerContainer.frame.size.height);
    [_audioControllerContainer addSubview:_audioPlayerViewController.view];

    [_audioPlayerViewController setupPlayer];

    [_audioPlayerViewController loadAudioFile:_previewedResource.filePath];
}

- (void)populateInitialValues
{
    __weak PreviewAudioViewController *weakSelf = self;
    [self setInitialValues:^{
        weakSelf.format_ios_sound = [[weakSelf.projectSettings propertyForResource:weakSelf.previewedResource andKey:RESOURCE_PROPERTY_IOS_SOUND] intValue];
        weakSelf.format_ios_sound_quality = [[weakSelf.projectSettings propertyForResource:weakSelf.previewedResource andKey:RESOURCE_PROPERTY_IOS_SOUND_QUALITY] intValue];
        weakSelf.format_ios_sound_quality_enabled = weakSelf.format_ios_sound != 0;

        weakSelf.format_android_sound = [[weakSelf.projectSettings propertyForResource:weakSelf.previewedResource andKey:RESOURCE_PROPERTY_ANDROID_SOUND] intValue];
        weakSelf.format_android_sound_quality = [[weakSelf.projectSettings propertyForResource:weakSelf.previewedResource andKey:RESOURCE_PROPERTY_ANDROID_SOUND_QUALITY] intValue];
        weakSelf.format_android_sound_quality_enabled = YES;
    }];
}

- (void)initializeIcon
{
    NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFileType:@"wav"];
    [icon setScalesWhenResized:YES];
    icon.size = NSMakeSize(128, 128);
    [_iconImage setImage:icon];
}

- (void)setFormat_ios_sound:(int)format_ios_sound
{
    _format_ios_sound = format_ios_sound;
    [self setValue:@(format_ios_sound) withName:RESOURCE_PROPERTY_IOS_SOUND isAudio:YES];

    self.format_ios_sound_quality_enabled = format_ios_sound != 0;
}

- (void)setFormat_android_sound:(int)format_android_sound
{
    _format_android_sound = format_android_sound;
    [self setValue:@(format_android_sound) withName:RESOURCE_PROPERTY_ANDROID_SOUND isAudio:YES];

    self.format_android_sound_quality_enabled = YES;
}

- (void)setFormat_ios_sound_quality:(int)format_ios_sound_quality
{
    _format_ios_sound_quality = format_ios_sound_quality;
    [self setValue:@(format_ios_sound_quality) withName:RESOURCE_PROPERTY_IOS_SOUND_QUALITY isAudio:YES];
}

- (void)setFormat_android_sound_quality:(int)format_android_sound_quality
{
    _format_android_sound_quality = format_android_sound_quality;
    [self setValue:@(format_android_sound_quality) withName:RESOURCE_PROPERTY_ANDROID_SOUND_QUALITY isAudio:YES];
}

@end
