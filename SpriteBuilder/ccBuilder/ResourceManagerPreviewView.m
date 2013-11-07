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

#import "ResourceManagerPreviewView.h"
#import "ResourceManager.h"
#import "ResourceManagerUtil.h"
#import "CCBImageView.h"
#import "AppDelegate.h"
#import "ProjectSettings.h"
#import "FCFormatConverter.h"
#import <AVFoundation/AVFoundation.h>

@implementation ResourceManagerPreviewView

#pragma mark Properties

@synthesize previewMain;
@synthesize previewPhone;
@synthesize previewPhonehd;
@synthesize previewTablet;
@synthesize previewTablethd;

#pragma mark Setup

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    [previewMain setAllowsCutCopyPaste:NO];
    [previewPhone setAllowsCutCopyPaste:NO];
    [previewPhonehd setAllowsCutCopyPaste:NO];
    [previewTablet setAllowsCutCopyPaste:NO];
    [previewTablethd setAllowsCutCopyPaste:NO];
}

- (AppDelegate*) appDelegate
{
    return [AppDelegate appDelegate];
}

- (void) resetView
{
    // Clear all previews
    [previewMain setImage:NULL];
    [previewPhone setImage:NULL];
    [previewPhonehd setImage:NULL];
    [previewTablet setImage:NULL];
    [previewTablethd setImage:NULL];
    self.imgMain = NULL;
    self.imgPhone = NULL;
    self.imgPhonehd = NULL;
    self.imgTablet = NULL;
    self.imgTablethd = NULL;
    
    _previewedResource = NULL;
    
    self.enabled = NO;
    self.scaleFrom = 0;
    
    self.format_ios_compress_enabled = NO;
    self.format_ios_dither_enabled = NO;
    self.format_ios_compress = NO;
    self.format_ios_dither = NO;
}

- (void) setPreviewFile:(id) selection
{
    [self resetView];
    
    [viewGeneric setHidden:YES];
    [viewImage setHidden:YES];
    [viewSpriteSheet setHidden:YES];
    [viewSound setHidden:YES];
    [viewCCB setHidden:YES];
    
    ProjectSettings* settings = [self appDelegate].projectSettings;
    
    // Update previews for different resolutions
    if ([selection isKindOfClass:[RMResource class]])
    {
        RMResource* res = (RMResource*) selection;
        
        _previewedResource = res;
        
        if (res.type == kCCBResTypeImage)
        {
            // Setup preview for image resource
            self.imgMain = [selection previewForResolution:@"auto"];
            self.imgPhone = [selection previewForResolution:@"phone"];
            self.imgPhonehd = [selection previewForResolution:@"phonehd"];
            self.imgTablet = [selection previewForResolution:@"tablet"];
            self.imgTablethd = [selection previewForResolution:@"tablethd"];
            
            [previewMain setImage: self.imgMain];
            [previewPhone setImage:self.imgPhone];
            [previewPhonehd setImage:self.imgPhonehd];
            [previewTablet setImage:self.imgTablet];
            [previewTablethd setImage:self.imgTablethd];
            
            // Load settings
            self.scaleFrom = [[settings valueForResource:res andKey:@"scaleFrom"] intValue];
            
            self.format_ios = [[settings valueForResource:res andKey:@"format_ios"] intValue];
            self.format_ios_dither = [[settings valueForResource:res andKey:@"format_ios_dither"] boolValue];
            self.format_ios_compress = [[settings valueForResource:res andKey:@"format_ios_compress"] boolValue];
            
            self.format_android = [[settings valueForResource:res andKey:@"format_android"] intValue];
            self.format_android_dither = [[settings valueForResource:res andKey:@"format_android_dither"] boolValue];
            self.format_android_compress = [[settings valueForResource:res andKey:@"format_android_compress"] boolValue];
            
            int tabletScale = [[settings valueForResource:res andKey:@"tabletScale"] intValue];
            if (!tabletScale) tabletScale = 2;
            self.tabletScale = tabletScale;
            
            self.enabled = YES;
            
            [viewImage setHidden:NO];
        }
        else if (res.type == kCCBResTypeDirectory && [res.data isDynamicSpriteSheet])
        {
            // Setup preview for smart sprite sheet
            self.format_ios = [[settings valueForResource:res andKey:@"format_ios"] intValue];
            self.format_ios_dither = [[settings valueForResource:res andKey:@"format_ios_dither"] boolValue];
            self.format_ios_compress = [[settings valueForResource:res andKey:@"format_ios_compress"] boolValue];
            
            self.format_android = [[settings valueForResource:res andKey:@"format_android"] intValue];
            self.format_android_dither = [[settings valueForResource:res andKey:@"format_android_dither"] boolValue];
            self.format_android_compress = [[settings valueForResource:res andKey:@"format_android_compress"] boolValue];
            
            NSString* imgPreviewPath = [res.filePath stringByAppendingPathExtension:@"ppng"];
            NSImage* img = [[[NSImage alloc] initWithContentsOfFile:imgPreviewPath] autorelease];
            if (!img)
            {
                img = [NSImage imageNamed:@"ui-nopreview.png"];
            }
            
            [previewSpriteSheet setImage:img];
            
            self.enabled = YES;
            
            [viewSpriteSheet setHidden:NO];
        }
        else if (res.type == kCCBResTypeAudio)
        {
            // Setup preview for sounds
            self.format_ios_sound =[[settings valueForResource:res andKey:@"format_ios_sound"] intValue];
            self.format_ios_sound_quality =[[settings valueForResource:res andKey:@"format_ios_sound_quality"] intValue];
            
            self.format_android_sound =[[settings valueForResource:res andKey:@"format_android_sound"] intValue];
            self.format_android_sound_quality =[[settings valueForResource:res andKey:@"format_android_sound_quality"] intValue];
            
            // Update icon
            NSImage* icon = [[NSWorkspace sharedWorkspace] iconForFileType:@"wav"];
            [icon setScalesWhenResized:YES];
            icon.size = NSMakeSize(128, 128);
            //[previewSoundImage setImage:icon];
            
            // Update sound
            QTMovie* movie = [QTMovie movieWithFile:res.filePath error:NULL];
            
            [previewSound setMovie:movie];
            
            [previewSound pause:NULL];
            [previewSound gotoBeginning:NULL];
            
            self.enabled = YES;
            
            [viewSound setHidden:NO];
            
            
            NSImage * waveformImage = [self renderImageForAudioAsset:[AVURLAsset assetWithURL:[NSURL fileURLWithPath:res.filePath]]];
            
            [previewSoundImage setImage:waveformImage];
            
        }
        else if (res.type == kCCBResTypeCCBFile)
        {
            NSString* imgPreviewPath = [res.filePath stringByAppendingPathExtension:@"ppng"];
            NSImage* img = [[[NSImage alloc] initWithContentsOfFile:imgPreviewPath] autorelease];
            if (!img)
            {
                img = [NSImage imageNamed:@"ui-nopreview.png"];
            }
            
            [previewCCB setImage:img];
            
            [viewCCB setHidden:NO];
        }
        else
        {
            [viewGeneric setHidden:NO];
        }
    }
    else
    {
        [viewGeneric setHidden:NO];
    }
}

#pragma mark Callbacks

- (NSString*) resolutionDirectoryForImageView:(NSImageView*) imgView
{
    NSString* resolution = NULL;
    if (imgView == previewMain) resolution = @"auto";
    else if (imgView == previewPhone) resolution = @"phone";
    else if (imgView == previewPhonehd) resolution = @"phonehd";
    else if (imgView == previewTablet) resolution = @"tablet";
    else if (imgView == previewTablethd) resolution = @"tablethd";
    
    if (!resolution) return NULL;
    
    return [@"resources-" stringByAppendingString:resolution];
}

- (IBAction)droppedFile:(id)sender
{
    if (![AppDelegate appDelegate].projectSettings)
    {
        [self resetView];
        return;
    }
    
    if (!_previewedResource)
    {
        return;
    }
    
    CCBImageView* imgView = sender;
    
    NSString* srcImagePath = imgView.imagePath;
    
    if (![[[srcImagePath pathExtension] lowercaseString] isEqualToString:@"png"])
    {
        // Only png is supported
        [self.appDelegate modalDialogTitle:@"Unsupported Format" message:@"Sorry, only png images are supported as source images."];
        return;
    }
    
    NSString* resolution = [self resolutionDirectoryForImageView:imgView];
    if (!resolution) return;
    
    // Calc dst path
    NSString* dir = [_previewedResource.filePath stringByDeletingLastPathComponent];
    NSString* file = [_previewedResource.filePath lastPathComponent];
    
    NSString* dstFile = [[dir stringByAppendingPathComponent:resolution] stringByAppendingPathComponent:file];
    
    // Create directory if it doesn't exist
    NSFileManager* fm = [NSFileManager defaultManager];
    [fm createDirectoryAtPath:[dstFile stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:NULL error:NULL];
    
    // Copy file
    [fm removeItemAtPath:dstFile error:NULL];
    [fm copyItemAtPath:srcImagePath toPath:dstFile error:NULL];
    
    // Reload open document
    [[AppDelegate appDelegate] reloadResources];
}

- (IBAction)actionRemoveFile:(id)sender
{
    if (!_previewedResource) return;
    
    CCBImageView* imgView = NULL;
    int tag = [sender tag];
    if (tag == 0) imgView = previewPhone;
    else if (tag == 1) imgView = previewPhonehd;
    else if (tag == 2) imgView = previewTablet;
    else if (tag == 3) imgView = previewTablethd;
    
    if (!imgView) return;
    
    NSString* resolution = [self resolutionDirectoryForImageView:imgView];
    if (!resolution) return;
    
    NSString* dir = [_previewedResource.filePath stringByDeletingLastPathComponent];
    NSString* file = [_previewedResource.filePath lastPathComponent];
    
    NSString* rmFile = [[dir stringByAppendingPathComponent:resolution] stringByAppendingPathComponent:file];
    
    // Remove file
    NSFileManager* fm = [NSFileManager defaultManager];
    [fm removeItemAtPath:rmFile error:NULL];
    
    // Remove from view
    imgView.image = NULL;
    
    // Reload open document
    [[AppDelegate appDelegate] reloadResources];
}

#pragma mark Edit properties

- (void) setScaleFrom:(int)scaleFrom
{
    _scaleFrom = scaleFrom;
    
    ProjectSettings* settings = [self appDelegate].projectSettings;
    
    if (_previewedResource)
    {
        // Return if the value hasn't changed
        int oldScaleFrom = [settings valueForResource:_previewedResource andKey:@"scaleFrom"];
        if (oldScaleFrom == scaleFrom) return;
        
        if (scaleFrom)
        {
            [settings setValue:[NSNumber numberWithInt:scaleFrom] forResource:_previewedResource andKey:@"scaleFrom"];
        }
        else
        {
            [settings removeObjectForResource:_previewedResource andKey:@"scaleFrom"];
        }
        
        // Reload the resource
        [ResourceManager touchResource:_previewedResource];
        [[AppDelegate appDelegate] reloadResources];
    }
}

- (BOOL) supportsCompress_ios:(int)format
{
    if (format == kFCImageFormatPVR_RGBA8888) return YES;
    if (format == kFCImageFormatPVR_RGBA4444) return YES;
    if (format == kFCImageFormatPVR_RGB565) return YES;
    if (format == kFCImageFormatPVRTC_2BPP) return YES;
    if (format == kFCImageFormatPVRTC_4BPP) return YES;
    return NO;
}

- (BOOL) supportsCompress_android:(int)format
{
    return NO;
}

- (BOOL) supportsDither_ios:(int)format
{
    if (format == kFCImageFormatPNG_8BIT) return YES;
    if (format == kFCImageFormatPVR_RGBA4444) return YES;
    if (format == kFCImageFormatPVR_RGB565) return YES;
    return NO;
}

- (BOOL) supportsDither_android:(int)format
{
    if (format == kFCImageFormatPNG_8BIT) return YES;
    if (format == kFCImageFormatPVR_RGBA4444) return YES;
    if (format == kFCImageFormatPVR_RGB565) return YES;
    return NO;
}

- (void) setFormat_ios:(int)format_ios
{
    _format_ios = format_ios;
    
    ProjectSettings* settings = [self appDelegate].projectSettings;
    
    if (_previewedResource)
    {
        if (format_ios)
        {
            [settings setValue:[NSNumber numberWithInt:format_ios] forResource:_previewedResource andKey:@"format_ios"];
        }
        else
        {
            [settings removeObjectForResource:_previewedResource andKey:@"format_ios"];
        }
        
        self.format_ios_dither_enabled = [self supportsDither_ios:format_ios];
        self.format_ios_compress_enabled = [self supportsCompress_ios:format_ios];
    }
}

- (void) setFormat_android:(int)format_android
{
    _format_android = format_android;
    
    ProjectSettings* settings = [self appDelegate].projectSettings;
    
    if (_previewedResource)
    {
        if (format_android)
        {
            [settings setValue:[NSNumber numberWithInt:format_android] forResource:_previewedResource andKey:@"format_android"];
        }
        else
        {
            [settings removeObjectForResource:_previewedResource andKey:@"format_android"];
        }
        
        self.format_android_dither_enabled = [self supportsDither_android:format_android];
        self.format_android_compress_enabled = [self supportsCompress_android:format_android];
    }
}

- (void) setFormat_ios_dither:(BOOL)format_ios_dither
{
    _format_ios_dither = format_ios_dither;
    
    ProjectSettings* settings = [self appDelegate].projectSettings;
    
    if (_previewedResource)
    {
        if (format_ios_dither)
        {
            [settings setValue:[NSNumber numberWithBool:format_ios_dither] forResource:_previewedResource andKey:@"format_ios_dither"];
        }
        else
        {
            [settings removeObjectForResource:_previewedResource andKey:@"format_ios_dither"];
        }
    }
}

- (void) setFormat_android_dither:(BOOL)format_android_dither
{
    _format_android_dither = format_android_dither;
    
    ProjectSettings* settings = [self appDelegate].projectSettings;
    
    if (_previewedResource)
    {
        if (format_android_dither)
        {
            [settings setValue:[NSNumber numberWithBool:format_android_dither] forResource:_previewedResource andKey:@"format_android_dither"];
        }
        else
        {
            [settings removeObjectForResource:_previewedResource andKey:@"format_android_dither"];
        }
    }
}

- (void) setFormat_ios_compress:(BOOL)format_ios_compress
{
    _format_ios_compress = format_ios_compress;
    
    ProjectSettings* settings = [self appDelegate].projectSettings;
    
    if (_previewedResource)
    {
        if (format_ios_compress)
        {
            [settings setValue:[NSNumber numberWithBool:format_ios_compress] forResource:_previewedResource andKey:@"format_ios_compress"];
        }
        else
        {
            [settings removeObjectForResource:_previewedResource andKey:@"format_ios_compress"];
        }
    }
}

- (void) setFormat_android_compress:(BOOL)format_android_compress
{
    _format_android_compress = format_android_compress;
    
    ProjectSettings* settings = [self appDelegate].projectSettings;
    
    if (_previewedResource)
    {
        if (format_android_compress)
        {
            [settings setValue:[NSNumber numberWithBool:format_android_compress] forResource:_previewedResource andKey:@"format_android_compress"];
        }
        else
        {
            [settings removeObjectForResource:_previewedResource andKey:@"format_android_compress"];
        }
    }
}

- (void) setTabletScale:(int)tabletScale
{
    if (_tabletScale == tabletScale)
    {
        return;
    }
    
    _tabletScale = tabletScale;
    
    ProjectSettings* settings = [self appDelegate].projectSettings;
    
    // Return if tabletScale hasn't changed
    int oldTabletScale = [[settings valueForResource:_previewedResource andKey:@"tabletScale"] intValue];
    if (tabletScale == oldTabletScale) return;
    if (tabletScale == 2 && !oldTabletScale) return;
    
    // Update value and reload assets
    if (tabletScale != 2)
    {
        [settings setValue:[NSNumber numberWithInt:tabletScale] forResource:_previewedResource andKey:@"tabletScale"];
    }
    else
    {
        [settings removeObjectForResource:_previewedResource andKey:@"tabletScale"];
    }
    
    [ResourceManager touchResource:_previewedResource];
    [[AppDelegate appDelegate] reloadResources];
}

- (void) setFormat_ios_sound:(int)format_ios_sound
{
    _format_ios_sound = format_ios_sound;
    
    ProjectSettings* settings = [self appDelegate].projectSettings;
    
    if (_previewedResource)
    {
        [settings setValue:[NSNumber numberWithInt:format_ios_sound] forResource:_previewedResource andKey:@"format_ios_sound"];
        
        if (format_ios_sound) self.format_ios_sound_quality_enabled = YES;
        else self.format_ios_sound_quality_enabled = NO;
    }
}

- (void) setFormat_android_sound:(int)format_android_sound
{
    _format_android_sound = format_android_sound;
    
    ProjectSettings* settings = [self appDelegate].projectSettings;
    
    if (_previewedResource)
    {
        [settings setValue:[NSNumber numberWithInt:format_android_sound] forResource:_previewedResource andKey:@"format_android_sound"];
        self.format_android_sound_quality_enabled = YES;
    }
}

- (void) setFormat_ios_sound_quality:(int)format_ios_sound_quality
{
    _format_ios_sound_quality = format_ios_sound_quality;
    
    ProjectSettings* settings = [self appDelegate].projectSettings;
    
    if (_previewedResource)
    {
        [settings setValue:[NSNumber numberWithInt:format_ios_sound_quality] forResource:_previewedResource andKey:@"format_ios_sound_quality"];
    }
}

- (void) setFormat_android_sound_quality:(int)format_android_sound_quality
{
    _format_android_sound_quality = format_android_sound_quality;
    
    ProjectSettings* settings = [self appDelegate].projectSettings;
    
    if (_previewedResource)
    {
        [settings setValue:[NSNumber numberWithInt:format_android_sound_quality] forResource:_previewedResource andKey:@"format_android_sound_quality"];
    }
}

#pragma mark Audio Display

- (NSImage *) renderImageForAudioAsset:(AVURLAsset *)audioAssets {
    
    NSError * error = nil;
    AVAssetReader * reader = [[AVAssetReader alloc] initWithAsset:audioAssets error:&error];
    AVAssetTrack * songTrack = [audioAssets.tracks objectAtIndex:0];
    
    NSDictionary* outputSettingsDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                                        
                                        [NSNumber numberWithInt:kAudioFormatLinearPCM],AVFormatIDKey,
                                        //     [NSNumber numberWithInt:44100.0],AVSampleRateKey, /*Not Supported*/
                                        //     [NSNumber numberWithInt: 2],AVNumberOfChannelsKey,    /*Not Supported*/
                                        
                                        [NSNumber numberWithInt:16],AVLinearPCMBitDepthKey,
                                        [NSNumber numberWithBool:NO],AVLinearPCMIsBigEndianKey,
                                        [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
                                        [NSNumber numberWithBool:NO],AVLinearPCMIsNonInterleaved,
                                        
                                        nil];
    
    
    AVAssetReaderTrackOutput* output = [[AVAssetReaderTrackOutput alloc] initWithTrack:songTrack outputSettings:outputSettingsDict];
    
    [reader addOutput:output];
    [output release];
    
    UInt32 sampleRate,channelCount;
    
    NSArray* formatDesc = songTrack.formatDescriptions;
    for(unsigned int i = 0; i < [formatDesc count]; ++i) {
        CMAudioFormatDescriptionRef item = (CMAudioFormatDescriptionRef)[formatDesc objectAtIndex:i];
        const AudioStreamBasicDescription* fmtDesc = CMAudioFormatDescriptionGetStreamBasicDescription (item);
        if(fmtDesc ) {
            
            sampleRate = fmtDesc->mSampleRate;
            channelCount = fmtDesc->mChannelsPerFrame;
            
            //    NSLog(@"channels:%u, bytes/packet: %u, sampleRate %f",fmtDesc->mChannelsPerFrame, fmtDesc->mBytesPerPacket,fmtDesc->mSampleRate);
        }
    }
    
    
    UInt32 bytesPerSample = 2 * channelCount;
    SInt16 normalizeMax = 0;
    
    NSMutableData * fullSongData = [[NSMutableData alloc] init];
    [reader startReading];
    
    
    UInt64 totalBytes = 0;
    SInt64 totalLeft = 0;
    SInt64 totalRight = 0;
    NSInteger sampleTally = 0;
    
    NSInteger samplesPerPixel = 0;//sampleRate / 50;
    
    while (reader.status == AVAssetReaderStatusReading){
        
        AVAssetReaderTrackOutput * trackOutput = (AVAssetReaderTrackOutput *)[reader.outputs objectAtIndex:0];
        CMSampleBufferRef sampleBufferRef = [trackOutput copyNextSampleBuffer];
        
        if (sampleBufferRef){
            CMBlockBufferRef blockBufferRef = CMSampleBufferGetDataBuffer(sampleBufferRef);
            
            size_t length = CMBlockBufferGetDataLength(blockBufferRef);
            totalBytes += length;
            
            
            NSAutoreleasePool *wader = [[NSAutoreleasePool alloc] init];
            
            NSMutableData * data = [NSMutableData dataWithLength:length];
            CMBlockBufferCopyDataBytes(blockBufferRef, 0, length, data.mutableBytes);
            
            
            SInt16 * samples = (SInt16 *) data.mutableBytes;
            int sampleCount = length / bytesPerSample;
            for (int i = 0; i < sampleCount ; i ++) {
                
                SInt16 left = *samples++;
                
                totalLeft  += left;
                
                
                
                SInt16 right;
                if (channelCount==2) {
                    right = *samples++;
                    
                    totalRight += right;
                }
                
                sampleTally++;
                
                if (sampleTally > samplesPerPixel) {
                    
                    left  = totalLeft / sampleTally;
                    
                    SInt16 fix = abs(left);
                    if (fix > normalizeMax) {
                        normalizeMax = fix;
                    }
                    
                    
                    [fullSongData appendBytes:&left length:sizeof(left)];
                    
                    if (channelCount==2) {
                        right = totalRight / sampleTally;
                        
                        
                        SInt16 fix = abs(right);
                        if (fix > normalizeMax) {
                            normalizeMax = fix;
                        }
                        
                        
                        [fullSongData appendBytes:&right length:sizeof(right)];
                    }
                    
                    totalLeft   = 0;
                    totalRight  = 0;
                    sampleTally = 0;
                    
                }
            }
            
            
            
            [wader drain];
            
            
            CMSampleBufferInvalidate(sampleBufferRef);
            
            CFRelease(sampleBufferRef);
        }
    }
    
    
    NSImage *waveformImage = nil;
    
    if (reader.status == AVAssetReaderStatusFailed || reader.status == AVAssetReaderStatusUnknown){
        // Something went wrong. return nil
        
        return nil;
    }
    
    if (reader.status == AVAssetReaderStatusCompleted){
        
        NSLog(@"rendering output graphics using normalizeMax %d",normalizeMax);
        
        waveformImage = [self audioImageGraph:(SInt16 *)
                         fullSongData.bytes 
                                 normalizeMax:normalizeMax 
                                  sampleCount:fullSongData.length / 4 
                                 channelCount:channelCount
                                  imageHeight:previewSoundImage.frame.size.height];
        
 
    }
    
    [fullSongData release];
    [reader release];
    
    return waveformImage;
}


-(NSImage *) audioImageGraph:(SInt16 *) samples
                normalizeMax:(SInt16) normalizeMax
                 sampleCount:(NSInteger) sampleCount
                channelCount:(NSInteger) channelCount
                 imageHeight:(float) imageHeight {
    
    CGSize imageSize = CGSizeMake(sampleCount, imageHeight);
 

    NSBitmapImageRep *offscreenRep = [[[NSBitmapImageRep alloc]
                                       initWithBitmapDataPlanes:NULL
                                       pixelsWide:sampleCount
                                       pixelsHigh:imageHeight
                                       bitsPerSample:8
                                       samplesPerPixel:4
                                       hasAlpha:YES
                                       isPlanar:NO
                                       colorSpaceName:NSDeviceRGBColorSpace
                                       bitmapFormat:NSAlphaFirstBitmapFormat
                                       bytesPerRow:0
                                       bitsPerPixel:0] autorelease];
    
    NSGraphicsContext * graphicsContext = [NSGraphicsContext graphicsContextWithBitmapImageRep:offscreenRep];
    
    CGContextRef context = [graphicsContext graphicsPort];
    
    CGContextSetFillColorWithColor(context, [NSColor blackColor].CGColor);
    CGContextSetAlpha(context,1.0);
    CGRect rect;
    rect.size = imageSize;
    rect.origin.x = 0;
    rect.origin.y = 0;
    
    CGColorRef leftcolor = [[NSColor whiteColor] CGColor];
    CGColorRef rightcolor = [[NSColor redColor] CGColor];
    
    CGContextFillRect(context, rect);
    
    CGContextSetLineWidth(context, 1.0);
    
    float halfGraphHeight = (imageHeight / 2) / (float) channelCount ;
    float centerLeft = halfGraphHeight;
    float centerRight = (halfGraphHeight*3) ;
    float sampleAdjustmentFactor = (imageHeight/ (float) channelCount) / (float) normalizeMax / 2.0f;
    
    for (NSInteger intSample = 0 ; intSample < sampleCount ; intSample ++ ) {
        SInt16 left = *samples++;
        float pixels = (float) left;
        pixels *= sampleAdjustmentFactor;
        CGContextMoveToPoint(context, intSample, centerLeft-pixels);
        CGContextAddLineToPoint(context, intSample, centerLeft+pixels);
        CGContextSetStrokeColorWithColor(context, leftcolor);
        CGContextStrokePath(context);
        
        if (channelCount==2) {
            SInt16 right = *samples++;
            float pixels = (float) right;
            pixels *= sampleAdjustmentFactor;
            CGContextMoveToPoint(context, intSample, centerRight - pixels);
            CGContextAddLineToPoint(context, intSample, centerRight + pixels);
            CGContextSetStrokeColorWithColor(context, rightcolor);
            CGContextStrokePath(context);
        }
    }
    
    [NSGraphicsContext restoreGraphicsState];
    
    NSImage *img = [[[NSImage alloc] initWithSize:imageSize] autorelease];
    [img addRepresentation:offscreenRep];

    
    
    return img;
}

#pragma mark Split view constraints

- (CGFloat) splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex
{
    if (proposedMinimumPosition < 160) return 160;
    else return proposedMinimumPosition;
}

- (CGFloat) splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMaximumPosition ofSubviewAt:(NSInteger)dividerIndex
{
    float max = splitView.frame.size.height - 100;
    if (proposedMaximumPosition > max) return max;
    else return proposedMaximumPosition;
}

- (void) dealloc
{
    self.imgMain = NULL;
    self.imgPhone = NULL;
    self.imgPhonehd = NULL;
    self.imgTablet = NULL;
    self.imgTablethd = NULL;
    
    [super dealloc];
}

@end
