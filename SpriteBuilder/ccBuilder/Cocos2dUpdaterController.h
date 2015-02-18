//
// Created by Nicky Weber on 12.02.15.
//

#import <Foundation/Foundation.h>
#import "Cocos2dUpdateDelegate.h"

@class ProjectSettings;
@class AppDelegate;


@interface Cocos2dUpdaterController : NSObject <Cocos2dUpdateDelegate>

@property (nonatomic, weak, readonly) AppDelegate *appDelegate;
@property (nonatomic, weak, readonly) ProjectSettings *projectSettings;

- (instancetype)initWithAppDelegate:(AppDelegate *)appDelegate projectSettings:(ProjectSettings *)projectSettings;

- (void)updateAndBypassIgnore:(BOOL)bypassIgnore;

@end