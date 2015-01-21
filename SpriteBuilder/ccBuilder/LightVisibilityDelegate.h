//
//  LightVisibilityDelegate.h
//  SpriteBuilder
//
//  Created by Thayer J Andrews on 12/15/14.
//
//

#import <Foundation/Foundation.h>

@class CCLightNode;

@protocol LightVisibilityDelegate

- (void)lightVisibilityWillChange:(CCLightNode *)light;
- (void)lightVisibilityDidChange:(CCLightNode *)light;

@end
