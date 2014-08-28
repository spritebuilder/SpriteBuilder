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
#import "ResourceManager.h"
#import "NotificationNames.h"
#import "ProjectSettings.h"
#import "AudioPlayerViewController.h"

@interface PreviewAudioViewController ()

@property (nonatomic, strong) RMResource *previewedResource;
@property (nonatomic, weak) ProjectSettings *projectSettings;
@property (nonatomic, strong) AudioPlayerViewController *audioPlayerViewController;
@property (nonatomic) BOOL initialUpdate;

@end


@implementation PreviewAudioViewController

- (void)setPreviewedResource:(RMResource *)previewedResource projectSettings:(ProjectSettings *)projectSettings
{
    [_androidSettingsContainer setHidden:!IS_SPRITEBUILDER_PRO];

    self.projectSettings = projectSettings;
    _previewedResource = previewedResource;

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
    self.initialUpdate = YES;
    
    self.format_ios_sound = [[_projectSettings propertyForResource:_previewedResource andKey:RESOURCE_PROPERTY_IOS_SOUND] intValue];
    self.format_ios_sound_quality = [[_projectSettings propertyForResource:_previewedResource andKey:RESOURCE_PROPERTY_IOS_SOUND_QUALITY] intValue];
    self.format_ios_sound_quality_enabled = _format_ios_sound != 0;

    self.format_android_sound = [[_projectSettings propertyForResource:_previewedResource andKey:RESOURCE_PROPERTY_ANDROID_SOUND] intValue];
    self.format_android_sound_quality = [[_projectSettings propertyForResource:_previewedResource andKey:RESOURCE_PROPERTY_ANDROID_SOUND_QUALITY] intValue];
    self.format_android_sound_quality_enabled = YES;

    self.initialUpdate = NO;
}

- (void)initializeIcon
{
    NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFileType:@"wav"];
    [icon setScalesWhenResized:YES];
    icon.size = NSMakeSize(128, 128);
    [_iconImage setImage:icon];
}

- (void)setValue:(id)value withName:(NSString *)name isAudio:(BOOL)isAudio
{
    if (!_previewedResource
        || _initialUpdate)
    {
        return;
    }

    // There's a inconsistency here for audio settings, no default values assumed by a absent key
    if ([value intValue] || isAudio)
    {
        [_projectSettings setProperty:value forResource:_previewedResource andKey:name];
    }
    else
    {
        [_projectSettings removePropertyForResource:_previewedResource andKey:name];
    }

    // Reload the resource
    [ResourceManager touchResource:_previewedResource];
    [[NSNotificationCenter defaultCenter] postNotificationName:RESOURCES_CHANGED object:nil];
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
