//
//  LightingHandler.h
//  SpriteBuilder
//
//  Created by Thayer J Andrews on 12/12/14.
//
//

#import "LightVisibilityDelegate.h"

#import <Foundation/Foundation.h>

@interface LightingHandler : NSObject <LightVisibilityDelegate>

@property (nonatomic, weak) IBOutlet NSMenuItem *stageLightMenu;
@property (nonatomic, assign) BOOL showLights;

- (void)refreshAll;
- (void)refreshStageLightAndMenu;

- (void)lightVisibilityWillChange:(CCLightNode *)lightNode;
- (void)lightVisibilityDidChange:(CCLightNode *)lightNode;

@end
