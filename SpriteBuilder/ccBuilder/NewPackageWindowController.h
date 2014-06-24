//
//  NewPackageWindowController.h
//  SpriteBuilder
//
//  Created by Nicky Weber on 22.05.14.
//
//

#import <Cocoa/Cocoa.h>

@class PackageCreator;
@class PackageImporter;

@interface NewPackageWindowController : NSWindowController

@property (nonatomic, readonly, copy) NSString *packageName;
@property (nonatomic, strong) PackageCreator *packageCreator;

- (IBAction)onCreate:(id)sender;
- (IBAction)onCancel:(id)sender;

@end
