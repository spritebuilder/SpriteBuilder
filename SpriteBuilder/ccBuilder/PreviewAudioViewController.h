//
//  PreviewAudioViewController.h
//  SpriteBuilder
//
//  Created by Nicky Weber on 26.08.14.
//
//

#import <Cocoa/Cocoa.h>
#import "PreviewViewControllerProtocol.h"

@class ProjectSettings;
@class ResourceManagerPreviewAudio;

@interface PreviewAudioViewController : NSViewController <PreviewViewControllerProtocol>

@property (nonatomic, weak) IBOutlet NSView *androidSettingsContainer;
@property (nonatomic, weak) IBOutlet NSImageView *iconImage;
@property (nonatomic, weak) IBOutlet NSView *audioControllerContainer;

// Bindings
@property (nonatomic) int format_ios_sound;
@property (nonatomic) int format_ios_sound_quality;
@property (nonatomic) int format_ios_sound_quality_enabled;

@property (nonatomic) int format_android_sound;
@property (nonatomic) int format_android_sound_quality;
@property (nonatomic) int format_android_sound_quality_enabled;

@end
