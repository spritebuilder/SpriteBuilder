//
//  NewPackageWindowController.h
//  SpriteBuilder
//
//  Created by Nicky Weber on 22.05.14.
//
//

#import <Cocoa/Cocoa.h>

@protocol PackageCreateDelegateProtocol;

@interface NewPackageWindowController : NSWindowController

@property (nonatomic, readonly, copy) NSString *packageName;
@property (nonatomic, weak) id<PackageCreateDelegateProtocol>delegate;

- (IBAction)onCreate:(id)sender;
- (IBAction)onCancel:(id)sender;

@end
