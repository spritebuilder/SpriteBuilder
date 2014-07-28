//
//  PackageSettingsDetailView.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 24.07.14.
//
//

#import "PackageSettingsDetailView.h"
#import "PackagePublishSettings.h"

@implementation PackageSettingsDetailView

- (void)setShowAndroidSettings:(BOOL)showAndroidSettings
{
    _showAndroidSettings = showAndroidSettings;
    [_androidView setHidden:!showAndroidSettings];
}

@end
