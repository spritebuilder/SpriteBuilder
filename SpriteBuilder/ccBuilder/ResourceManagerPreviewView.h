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
@class ProjectSettings;

@interface ResourceManagerPreviewView : NSObject <NSSplitViewDelegate>

@property (nonatomic, weak) ProjectSettings *projectSettings;

@property (weak, nonatomic) IBOutlet NSView* viewGeneric;
@property (weak, nonatomic) IBOutlet NSView* viewImage;
@property (weak, nonatomic) IBOutlet NSView* viewSpriteSheet;
@property (weak, nonatomic) IBOutlet NSView* viewSound;
@property (weak, nonatomic) IBOutlet NSView* viewCCB;

@property (weak, nonatomic) IBOutlet NSImageView *previewCCB;
@property (weak, nonatomic) IBOutlet NSImageView *previewFallback;
@property (weak, nonatomic) IBOutlet NSView *previewSound;
@property (weak, nonatomic) IBOutlet NSImageView *previewSoundImage;
@property (weak, nonatomic) IBOutlet CCBImageView* previewSpriteSheet;

@property (weak, nonatomic) IBOutlet NSView *androidContainerImage;
@property (weak, nonatomic) IBOutlet NSView *androidContainerSpriteSheet;
@property (weak, nonatomic) IBOutlet NSView *androidContainerSound;

@property (weak, nonatomic) IBOutlet CCBImageView *previewMain;
@property (weak, nonatomic) IBOutlet CCBImageView *previewPhone;
@property (weak, nonatomic) IBOutlet CCBImageView *previewPhonehd;
@property (weak, nonatomic) IBOutlet CCBImageView *previewTablet;
@property (weak, nonatomic) IBOutlet CCBImageView *previewTablethd;

@property (nonatomic,strong) NSImage* imgMain;
@property (nonatomic,strong) NSImage* imgPhone;
@property (nonatomic,strong) NSImage* imgPhonehd;
@property (nonatomic,strong) NSImage* imgTablet;
@property (nonatomic,strong) NSImage* imgTablethd;

@property (nonatomic,readwrite) BOOL enabled;

@property (nonatomic,readwrite) int scaleFrom;
@property (nonatomic, assign) int tabletScale;

@property (nonatomic,readonly) BOOL format_supportsPVRTC;
@property (nonatomic,readwrite) BOOL trimSprites;

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


- (void)setPreviewResource:(id)resource;

@end
