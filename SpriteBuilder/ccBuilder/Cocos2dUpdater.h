//
//  Cocos2dUpater.h
//  SpriteBuilder
//
//  Created by Nicky Weber on 31.03.14.
//
//

@class AppDelegate;
@class ProjectSettings;

@interface Cocos2dUpdater : NSObject

@property (nonatomic, weak, readonly) AppDelegate *appDelegate;
@property (nonatomic, weak, readonly) ProjectSettings *projectSettings;

- (instancetype)initWithAppDelegate:(AppDelegate *)appDelegate projectSettings:(ProjectSettings *)projectSettings;

- (void)updateAndBypassIgnore:(BOOL)bypassIgnore;

@end
