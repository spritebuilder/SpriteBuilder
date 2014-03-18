//
//  PreferenceOptiPNGViewController.h
//  PreferenceWindow
//
//  Created by Nicky Weber on 18.03.14.
//  Copyright (c) 2014 Nicky Weber. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PreferenceOptiPNGViewController : NSViewController

- (IBAction)chooseOptiPNGInstallationPath:(id)sender;
- (IBAction)testOptiPNG:(id)sender;

@property (nonatomic, retain) IBOutlet NSTextField *optiPNGPathTextField;

@end
