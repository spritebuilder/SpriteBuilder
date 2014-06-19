//
//  NewPackageWindowController.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 22.05.14.
//
//

#import "NewPackageWindowController.h"

#import "PackageCreateDelegateProtocol.h"
#import "SBErrors.h"


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
        if (error.code == SBResourcePathExistsButNotInProjectError)
        {
            if (![self showImportExistingPackageDialogue])
            {
                return;
            }
        }
        else
        {
            [self showCannotCreatePackageWarningWithError:error];
            return;
        }
    }

    [NSApp stopModalWithCode:1];
}

- (BOOL)showImportExistingPackageDialogue
{
    NSAlert *alert = [NSAlert alertWithMessageText:@"Import"
                                     defaultButton:@"Yes"
                                   alternateButton:@"No"
                                       otherButton:nil
                         informativeTextWithFormat:@"A package already exists with that name, do you like to import it?"];

    NSInteger result = [alert runModal];

    return result == NSAlertDefaultReturn
           && [self importPackage];
}

- (BOOL)importPackage
{
    NSError *error;
    if ([_delegate importPackageWithName:_packageName error:&error])
    {
        return YES;
    }
    else
    {
        [self showCannotCreatePackageWarningWithError:error];
        return NO;
    }
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

@end
