//
//  EffectsManager.h
//  SpriteBuilder
//
//  Created by John Twigg on 6/23/14.
//
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@class EffectDescription;

@protocol EffectProtocol <NSObject>

@property (nonatomic,readonly) EffectDescription * effectDescription;
-(id)serialize;
-(void)deserialize:(NSDictionary*)dict;
+(CCEffect*)defaultConstruct;
@end


@interface EffectDescription : NSObject
{

}
@property (nonatomic) NSString * title;
@property (nonatomic) NSString * description;
@property (nonatomic) NSString * imageName;
@property (nonatomic) NSString * className;
@property (nonatomic) NSString * viewController;
@property (nonatomic) NSString * popupViewController;//Optional
-(CCEffect*)constructDefault;

@end



@interface EffectsManager : NSObject
+(NSArray*)effects;
+(EffectDescription*)effectByClassName:(NSString*)className;
@end
