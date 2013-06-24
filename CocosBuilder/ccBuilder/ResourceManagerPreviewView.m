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
#import "CCBImageView.h"
#import "CocosBuilderAppDelegate.h"
#import "ProjectSettings.h"
#import "Tupac.h"

@implementation ResourceManagerPreviewView

@synthesize previewMain;
@synthesize previewPhone;
@synthesize previewPhonehd;
@synthesize previewTablet;
@synthesize previewTablethd;

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    // Disable focus rings
    /*
    [previewMain setFocusRingType:NSFocusRingTypeNone];
    [previewPhone setFocusRingType:NSFocusRingTypeNone];
    [previewPhonehd setFocusRingType:NSFocusRingTypeNone];
    [previewTablet setFocusRingType:NSFocusRingTypeNone];
    [previewTablethd setFocusRingType:NSFocusRingTypeNone];
    */
    
    [previewMain setAllowsCutCopyPaste:NO];
    [previewPhone setAllowsCutCopyPaste:NO];
    [previewPhonehd setAllowsCutCopyPaste:NO];
    [previewTablet setAllowsCutCopyPaste:NO];
    [previewTablethd setAllowsCutCopyPaste:NO];
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
    
    // Update previews for different resolutions
    if ([selection isKindOfClass:[RMResource class]])
    {
        RMResource* res = (RMResource*) selection;
        
        _previewedResource = res;
        
        if (res.type == kCCBResTypeImage)
        {
            // Load previews
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
            ProjectSettings* settings = [self appDelegate].projectSettings;
            
            self.scaleFrom = [[settings valueForResource:res andKey:@"scaleFrom"] intValue];
            
            self.format_ios = [[settings valueForResource:res andKey:@"format_ios"] intValue];
            self.format_ios_dither = [[settings valueForResource:res andKey:@"format_ios_dither"] boolValue];
            self.format_ios_compress = [[settings valueForResource:res andKey:@"format_ios_compress"] boolValue];
            
            self.format_android = [[settings valueForResource:res andKey:@"format_android"] intValue];
            
            int tabletScale = [[settings valueForResource:res andKey:@"tabletScale"] intValue];
            if (!tabletScale) tabletScale = 2;
            self.tabletScale = tabletScale;
            
            self.enabled = YES;
        }
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
    if (![CocosBuilderAppDelegate appDelegate].projectSettings)
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
    
    NSLog(@"srcImagePath: %@", srcImagePath);
    
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
    
#warning Make sure assets are reloaded
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
    
    NSLog(@"imgView: %@", imgView);
    
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
}

- (void) setScaleFrom:(int)scaleFrom
{
    _scaleFrom = scaleFrom;
    
    ProjectSettings* settings = [self appDelegate].projectSettings;
    
    if (_previewedResource)
    {
        if (scaleFrom)
        {
            [settings setValue:[NSNumber numberWithInt:scaleFrom] forResource:_previewedResource andKey:@"scaleFrom"];
        }
        else
        {
            [settings removeObjectForResource:_previewedResource andKey:@"scaleFrom"];
        }
    }
}

- (BOOL) supportsCompress_ios:(int)format
{
    if (format == kTupacImageFormatPVR_RGBA8888) return YES;
    if (format == kTupacImageFormatPVR_RGBA4444) return YES;
    if (format == kTupacImageFormatPVR_RGB565) return YES;
    if (format == kTupacImageFormatPVRTC_2BPP) return YES;
    if (format == kTupacImageFormatPVRTC_4BPP) return YES;
    return NO;
}

- (BOOL) supportsCompress_android:(int)format
{
    return NO;
}

- (BOOL) supportsDither_ios:(int)format
{
    if (format == kTupacImageFormatPNG_8BIT) return YES;
    if (format == kTupacImageFormatPVR_RGBA4444) return YES;
    if (format == kTupacImageFormatPVR_RGB565) return YES;
    return NO;
}

- (BOOL) supportsDither_android:(int)format
{
    if (format == kTupacImageFormatPNG_8BIT) return YES;
    if (format == kTupacImageFormatPVR_RGBA4444) return YES;
    if (format == kTupacImageFormatPVR_RGB565) return YES;
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
    _tabletScale = tabletScale;
    
    ProjectSettings* settings = [self appDelegate].projectSettings;
    
    if (tabletScale != 2)
    {
        [settings setValue:[NSNumber numberWithInt:tabletScale] forResource:_previewedResource andKey:@"tabletScale"];
    }
    else
    {
        [settings removeObjectForResource:_previewedResource andKey:@"tabletScale"];
    }
}

- (CocosBuilderAppDelegate*) appDelegate
{
    return [CocosBuilderAppDelegate appDelegate];
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
