//
//  PackagePublishAccessoryView.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 22.07.14.
//
//

#import "PackagePublishAccessoryView.h"

@implementation PackagePublishAccessoryView

- (void)setShowAndroidSettings:(BOOL)showAndroidSettings
{
    if (_androidSettingsView.isHidden == !showAndroidSettings)
    {
        return;
    }

    if (!showAndroidSettings)
    {
        [_androidSettingsView setHidden:YES];
        [self setFrameSize:NSMakeSize(self.frame.size.width - _androidSettingsView.frame.size.width, self.frame.size.height)];
    }
    else
    {
        [_androidSettingsView setHidden:NO];
        [self setFrameSize:NSMakeSize(self.frame.size.width + _androidSettingsView.frame.size.width, self.frame.size.height)];
    }
}

@end
