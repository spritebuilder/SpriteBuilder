//
//  NewPackageWindowController.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 22.05.14.
//
//

#import "NewPackageWindowController.h"

#import "PackageCreateDelegateProtocol.h"


@interface NewPackageWindowController ()

@property (nonatomic, readwrite, copy) NSString *packageName;

@end


@implementation NewPackageWindowController

- (instancetype)init
{
    self = [super initWithWindowNibName:@"NewPackageWindow"];

    if (self)
    {
        self.packageName = @"UntitledPackage";
    }

    return self;
}

- (IBAction)onCreate:(id)sender
{
    NSAssert(_delegate != nil, @"No <PackageCreateDelegateProtocol> delegate set.");

    NSError *error;
    if (![_delegate createPackageWithName:_packageName error:&error])
    {
        [self showCannotCreatePackageWarningWithError:error];
        return;
    }

    [NSApp stopModalWithCode:1];
}

- (void)showCannotCreatePackageWarningWithError:(NSError *)error
{
    NSAlert *alert = [NSAlert alertWithMessageText:@"Error"
                                     defaultButton:@"Ok"
                                   alternateButton:nil
                                       otherButton:nil
                         informativeTextWithFormat:error.localizedDescription];

    [alert runModal];
}

- (IBAction)onCancel:(id)sender
{
    [NSApp stopModalWithCode:0];
}

- (void)windowDidLoad
{
    [super windowDidLoad];

    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

@end
