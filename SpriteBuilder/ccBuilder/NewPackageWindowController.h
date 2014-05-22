//
//  NewPackageWindowController.h
//  SpriteBuilder
//
//  Created by Nicky Weber on 22.05.14.
//
//

#import <Cocoa/Cocoa.h>

@protocol PackageCreateDelegate;

@interface NewPackageWindowController : NSWindowController <NSTextFieldDelegate>

@property (nonatomic, strong) IBOutlet NSTextField *packageNameInput;
@property (nonatomic, strong) IBOutlet NSTextField *errorMessage;
@property (nonatomic, readonly, copy) NSString *packageName;
@property (nonatomic, weak) id<PackageCreateDelegate>delegate;

- (IBAction)onCreate:(id)sender;
- (IBAction)onCancel:(id)sender;


@end
