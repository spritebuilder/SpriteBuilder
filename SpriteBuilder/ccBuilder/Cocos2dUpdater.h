//
//  Cocos2dUpater.h
//  SpriteBuilder
//
//  Created by Nicky Weber on 31.03.14.
//
//


typedef enum {
   UpdateActionUpdate = 0,
   UpdateActionNothingToDo,
   UpdateActionIgnoreVersion,
} UpdateActions;


@class AppDelegate;
@class ProjectSettings;
@protocol Cocos2dUpdateDelegate;

@interface Cocos2dUpdater : NSObject

@property (nonatomic, weak) id <Cocos2dUpdateDelegate> delegate;
@property (nonatomic, weak, readonly) AppDelegate *appDelegate;
@property (nonatomic, weak, readonly) ProjectSettings *projectSettings;

- (instancetype)initWithAppDelegate:(AppDelegate *)appDelegate projectSettings:(ProjectSettings *)projectSettings;

- (void)updateAndBypassIgnore:(BOOL)bypassIgnore;

@end
