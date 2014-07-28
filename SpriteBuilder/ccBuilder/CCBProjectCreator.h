//
//  CCBProjectCreator.h
//  SpriteBuilder
//
//  Created by Viktor on 10/11/13.
//
//

#import "ProjectSettings.h"

@interface CCBProjectCreator : NSObject

- (BOOL) createDefaultProjectAtPath:(NSString*)fileName engine:(CCBTargetEngine)engine;

@end
