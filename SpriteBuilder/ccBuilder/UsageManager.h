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

@property (readonly) NSString * userID;

- (void) registerUsage;
- (void) registerEmail:(NSString*)email reveiveNewsLetter:(BOOL)receiveNewsLetter;

- (void) sendEvent:(NSString*)evt;

- (void) setRegisterdEmailFlag;

//Returns a dictionary of information thats useful for tracking usage.
- (NSDictionary*)usageDetails;
- (NSString *)serialNumber;
@end
