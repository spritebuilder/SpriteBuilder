//
//  PreferencesController.h
//  PreferenceWindow
//
//  Created by Nicky Weber on 17.03.14.
//  Copyright (c) 2014 Nicky Weber. All rights reserved.
//
//  Usage: Add a NSToolBarItem to the toolbar in the preferences.xib and set an identifier: i.e. <coolitem>
//         Create a view controller named <coolitem>ViewController
//
//  Caveats: Only the height is adjusted to the height of the selected preference window, if a wieder window is needed
//           Adjust preferences.xib
//
//  Todo: Remember last selection

#import <Cocoa/Cocoa.h>

@interface PreferencesController : NSWindowController <NSWindowDelegate>

@property (nonatomic) IBOutlet NSToolbar *toolbar;

@end
