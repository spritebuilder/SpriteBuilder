//
//  PreviewSpriteSheetViewController.h
//  SpriteBuilder
//
//  Created by Nicky Weber on 26.08.14.
//
//

#import <Cocoa/Cocoa.h>
#import "PreviewViewControllerProtocol.h"

@class CCBImageView;
@class PreviewBaseViewController;

@interface PreviewSpriteSheetViewController : PreviewBaseViewController <PreviewViewControllerProtocol>

@property (nonatomic, weak) IBOutlet CCBImageView* previewSpriteSheet;

@property (nonatomic) BOOL trimSprites;

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
