//
//  RegistrationWindow.h
//  SpriteBuilder
//
//  Created by Viktor on 5/29/14.
//
//

#import <Cocoa/Cocoa.h>

@interface RegistrationWindow : NSWindowController <NSTextFieldDelegate>
{
    IBOutlet NSButton* _checkBox;
    IBOutlet NSTextField* _email;

}
@property (weak) IBOutlet NSButton *continueButton;
@property (weak) IBOutlet NSButton *cancelButton;
@property (weak) IBOutlet NSButton *signUpLaterButton;
@end

