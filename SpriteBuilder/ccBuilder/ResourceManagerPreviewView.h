/*
 * CocosBuilder: http://www.cocosbuilder.com
 *
 * Copyright (c) 2012 Zynga Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import <Foundation/Foundation.h>
#import <QTKit/QTKit.h>
#import <AVKit/AVKit.h>

@class CCBImageView;
@class AppDelegate;
@class RMResource;
@class ResourceManagerPreviewAudio;

@interface ResourceManagerPreviewView : NSObject <NSSplitViewDelegate>
{
    // Main views
    IBOutlet NSView* viewGeneric;
    IBOutlet NSView* viewImage;
    IBOutlet NSView* viewSpriteSheet;
    IBOutlet NSView* viewSound;
    IBOutlet NSView* viewCCB;
    
    // Image previews
    IBOutlet CCBImageView* __weak previewMain;
    IBOutlet CCBImageView* __weak previewPhone;
    IBOutlet CCBImageView* __weak previewPhonehd;
    IBOutlet CCBImageView* __weak previewTablet;
    IBOutlet CCBImageView* __weak previewTablethd;
    
    // Sprite sheet previews
    IBOutlet CCBImageView* previewSpriteSheet;
    
    // Sound preview
    //IBOutlet QTMovieView* previewSound;
    IBOutlet NSImageView* previewSoundImage;
    IBOutlet NSView     * previewSound;
    ResourceManagerPreviewAudio        * previewAudioViewController;

    
    // Generic fallback view
    IBOutlet NSImageView* previewGeneric;
    
    // CCB preivew
    IBOutlet NSImageView* previewCCB;
    
    RMResource* _previewedResource;
}
@property (weak, nonatomic,readonly) AppDelegate* appDelegate;

@property (weak, nonatomic) IBOutlet NSView *androidContainerImage;
@property (weak, nonatomic) IBOutlet NSView *androidContainerSpriteSheet;
@property (weak, nonatomic) IBOutlet NSView *androidContainerSound;

@property (weak, nonatomic,readonly) IBOutlet CCBImageView* previewMain;
@property (weak, nonatomic,readonly) IBOutlet CCBImageView* previewPhone;
@property (weak, nonatomic,readonly) IBOutlet CCBImageView* previewPhonehd;
@property (weak, nonatomic,readonly) IBOutlet CCBImageView* previewTablet;
@property (weak, nonatomic,readonly) IBOutlet CCBImageView* previewTablethd;

@property (nonatomic,strong) NSImage* imgMain;
@property (nonatomic,strong) NSImage* imgPhone;
@property (nonatomic,strong) NSImage* imgPhonehd;
@property (nonatomic,strong) NSImage* imgTablet;
@property (nonatomic,strong) NSImage* imgTablethd;

@property (nonatomic,readwrite) BOOL enabled;

@property (nonatomic,readwrite) int scaleFrom;

@property (nonatomic,readonly) BOOL format_supportsPVRTC;

@property (nonatomic,readwrite) int  format_ios;
@property (nonatomic,readwrite) BOOL format_ios_dither;
@property (nonatomic,readwrite) BOOL format_ios_compress;
@property (nonatomic,readwrite) BOOL format_ios_dither_enabled;
@property (nonatomic,readwrite) BOOL format_ios_compress_enabled;
@property (nonatomic,readwrite) int format_ios_sound;
@property (nonatomic,readwrite) int format_ios_sound_quality;
@property (nonatomic,readwrite) int format_ios_sound_quality_enabled;

@property (nonatomic,readwrite) int format_android;
@property (nonatomic,readwrite) BOOL format_android_dither;
@property (nonatomic,readwrite) BOOL format_android_compress;
@property (nonatomic,readwrite) BOOL format_android_dither_enabled;
@property (nonatomic,readwrite) BOOL format_android_compress_enabled;
@property (nonatomic,readwrite) int format_android_sound;
@property (nonatomic,readwrite) int format_android_sound_quality;
@property (nonatomic,readwrite) int format_android_sound_quality_enabled;

@property (nonatomic,readwrite) BOOL trimSprites;

@property (nonatomic, assign) int tabletScale;

- (void) setPreviewFile:(NSString*) file;

@end
