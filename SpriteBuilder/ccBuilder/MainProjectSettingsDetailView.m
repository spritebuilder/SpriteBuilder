#import "MainProjectSettingsDetailView.h"


@implementation MainProjectSettingsDetailView

- (void)setShowAndroidSettings:(BOOL)showAndroidSettings
{
    _showAndroidSettings = showAndroidSettings;
    [_androidView setHidden:!showAndroidSettings];
}

@end