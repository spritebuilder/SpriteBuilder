//
//  LicenseWindow.m
//  SpriteBuilder
//
//  Created by John Twigg on 7/18/14.
//
//

#import "LicenseWindow.h"

@interface LicenseWindow ()
@property (weak) IBOutlet NSButton *continueButton;

@end

@implementation LicenseWindow

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
	
	[self.continueButton setEnabled:NO];
    

}
- (IBAction)onHandleLoginToSBSite:(id)sender {
	
}

- (IBAction)onHandleContinue:(id)sender {
	
}
- (IBAction)onHandleQuit:(id)sender {
}

@end
