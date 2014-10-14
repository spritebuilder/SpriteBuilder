//
//  PreviewCCBViewController.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 27.08.14.
//
//

#import "PreviewViewControllerProtocol.h"
#import "PreviewCCBViewController.h"
#import "RMResource.h"
#import "ProjectSettings.h"
#import "MiscConstants.h"

@implementation PreviewCCBViewController

- (void)setPreviewedResource:(RMResource *)previewedResource projectSettings:(ProjectSettings *)projectSettings
{
   NSString *imgPreviewPath = [previewedResource.filePath stringByAppendingPathExtension:PNG_PREVIEW_IMAGE_SUFFIX];
   NSImage *img = [[NSImage alloc] initWithContentsOfFile:imgPreviewPath];
   if (!img)
   {
       img = [NSImage imageNamed:@"ui-nopreview.png"];
   }

   [_ccbPreviewImageView setImage:img];
}

@end
