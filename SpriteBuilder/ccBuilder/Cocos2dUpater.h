//
//  Cocos2dUpater.h
//  SpriteBuilder
//
//  Created by Nicky Weber on 31.03.14.
//
//

@class AppDelegate;
@class ProjectSettings;

@interface Cocos2dUpater : NSObject

@property (nonatomic, readonly) AppDelegate *appDelegate;
@property (nonatomic, readonly) ProjectSettings *projectSettings;

- (instancetype)initWithAppDelegate:(AppDelegate *)appDelegate projectSettings:(ProjectSettings *)projectSettings;

- (void)update;

@end
