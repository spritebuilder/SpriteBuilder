//
//  RegistrationWindow.m
//  SpriteBuilder
//
//  Created by Viktor on 5/29/14.
//
//

#import "RegistrationWindow.h"
#import "UsageManager.h"

@interface RegistrationWindow ()

@end

@implementation RegistrationWindow

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
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    
    NSMutableAttributedString* title = [_checkBox.attributedTitle mutableCopy];
    [title addAttribute:NSForegroundColorAttributeName value:[NSColor whiteColor] range:NSMakeRange(0, title.length)];
    _checkBox.attributedTitle = title;
}

- (IBAction) pressedContinue:(id)sender
{
    // Fetch email
    NSString* email = _email.stringValue;
    
    if (!email || [email isEqualToString:@""])
    {
        // The user choose not to sign up
    }
    else if (_checkBox.state == NSOnState)
    {
        // Check if email is valid
        if (![self isValidEmail])
        {
            [self.window makeFirstResponder:_email];
            NSBeep();
            return;
        }
        
        // Send it to the server
        [[[UsageManager alloc] init] registerEmail:email];
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:@"sbRegisteredEmail"];
    [self close];
}

- (IBAction) pressedLater:(id)sender
{
    [self close];
}

- (IBAction) pressedPrivacyPolicy:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://spritebuilder.com/privacy"]];
}

- (BOOL) isValidEmail
{
    if (!_email.stringValue) return NO;
    
    NSString *emailRegEx =
    @"(?:[a-z0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[a-z0-9!#$%\\&'*+/=?\\^_`{|}"
    @"~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\"
    @"x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-"
    @"z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5"
    @"]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-"
    @"9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21"
    @"-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])";
    
    NSPredicate *regExPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx];
    return [regExPredicate evaluateWithObject:_email.stringValue];
}

@end
