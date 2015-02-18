//
// Created by Nicky Weber on 12.02.15.
//

#import <Foundation/Foundation.h>
#import "Cocos2dUpdater.h"

@protocol Cocos2dUpdateDelegate <NSObject>

- (void)updateSucceeded;

- (void)updateFailedWithError:(NSError *)error;

- (UpdateActions)updateAction:(NSString *)text
       projectsCocos2dVersion:(NSString *)projectsCocos2dVersion
 spriteBuildersCocos2dVersion:(NSString *)spriteBuildersCocos2dVersion
                   backupPath:(NSString *)backupPath;

@end