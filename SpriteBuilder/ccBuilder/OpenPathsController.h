//
//  OpenPathsController.h
//  SpriteBuilder
//
//  Created by Nicky Weber on 19.11.14.
//
//

#import <Foundation/Foundation.h>

@class ProjectSettings;

@interface OpenPathsController : NSObject

@property (nonatomic, weak) IBOutlet NSMenuItem *openPathsMenuItem;
@property (nonatomic, weak) ProjectSettings *projectSettings;

- (void)populateOpenPathsMenuItems;

- (void)updateMenuItemsForPackages;

@end
