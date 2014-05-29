//
//  UsageManager.h
//  SpriteBuilder
//
//  Created by Viktor on 12/2/13.
//
//

#import <Foundation/Foundation.h>

@interface UsageManager : NSObject
{
    NSString* _userID;
}

- (void) registerUsage;

- (void) registerEmail:(NSString*)email;

@end
