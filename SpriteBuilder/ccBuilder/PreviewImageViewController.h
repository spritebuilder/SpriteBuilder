//
//  PreviewImageViewController.h
//  SpriteBuilder
//
//  Created by Nicky Weber on 26.08.14.
//
//

#import <Cocoa/Cocoa.h>
#import "PreviewViewControllerProtocol.h"
#import "PreviewBaseViewController.h"

@class ProjectSettings;
@class CCBImageView;

@interface PreviewImageViewController : PreviewBaseViewController <PreviewViewControllerProtocol>

@property (nonatomic, weak) IBOutlet CCBImageView *previewMain;
@property (nonatomic, weak) IBOutlet CCBImageView *previewPhone;
@property (nonatomic, weak) IBOutlet CCBImageView *previewPhonehd;
@property (nonatomic, weak) IBOutlet CCBImageView *previewTablet;
@property (nonatomic, weak) IBOutlet CCBImageView *previewTablethd;

// Bindings
@property (nonatomic, readonly) BOOL format_supportsPVRTC;

@property (nonatomic) int scaleFrom;
@property (nonatomic) int tabletScale;

@property (nonatomic) int  format_ios;
@property (nonatomic) BOOL format_ios_dither;
@property (nonatomic) BOOL format_ios_compress;
@property (nonatomic) BOOL format_ios_dither_enabled;
@property (nonatomic) BOOL format_ios_compress_enabled;

@property (nonatomic) int format_android;
@property (nonatomic) BOOL format_android_dither;
@property (nonatomic) BOOL format_android_compress;
@property (nonatomic) BOOL format_android_dither_enabled;
@property (nonatomic) BOOL format_android_compress_enabled;

@end
