//
//  UsageManager.h
//  SpriteBuilder
//
//  Created by Viktor on 12/2/13.
//
//

#import <Foundation/Foundation.h>

extern NSString * kSbRegisteredEmail;
extern NSString * kSbUserID;

@interface UsageManager : NSObject
{
    NSString* _userID;
}

- (void) registerUsage;

- (void) registerEmail:(NSString*)email reveiveNewsLetter:(BOOL)receiveNewsLetter;

-(void)setRegisterdEmailFlag;

@end
