//
//  PackageSettingsDetailView.h
//  SpriteBuilder
//
//  Created by Nicky Weber on 24.07.14.
//
//

#import <Cocoa/Cocoa.h>

@class PackagePublishSettings;

@interface PackageSettingsDetailView : NSView

@property (nonatomic, strong) IBOutlet NSView *androidView;
@property (nonatomic) BOOL showAndroidSettings;

@end
