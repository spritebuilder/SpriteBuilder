//
//  NewPackageWindowController.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 22.05.14.
//
//

#import "NewPackageWindowController.h"

#import "PackageCreator.h"

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
    NSAssert(_packageCreator != nil, @"No packageCreator set.");

    NSError *error;
    if (![_packageCreator createPackageWithName:_packageName error:&error])
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
                         informativeTextWithFormat:@"%@", error.localizedDescription];

    [alert runModal];
}

- (IBAction)onCancel:(id)sender
{
    [NSApp stopModalWithCode:0];
}

@end
