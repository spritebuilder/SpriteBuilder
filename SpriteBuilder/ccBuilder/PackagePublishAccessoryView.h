//
//  PackagePublishAccessoryView.h
//  SpriteBuilder
//
//  Created by Nicky Weber on 22.07.14.
//
//

#import <Cocoa/Cocoa.h>

@interface PackagePublishAccessoryView : NSView

@property (nonatomic, strong) IBOutlet NSView *androidSettingsView;
@property (nonatomic) BOOL showAndroidSettings;

@end
