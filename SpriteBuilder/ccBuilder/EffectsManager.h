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
@required
@property (nonatomic,readonly) EffectDescription * effectDescription;
+(CCEffect<CCEffectProtocol>*)defaultConstruct;
-(id)serialize;
-(void)deserialize:(NSDictionary*)dict;

@end


@interface EffectDescription : NSObject
{

}
@property (nonatomic) NSString * title; //Title of the effect.
@property (nonatomic) NSString * description;//Short description.
@property (nonatomic) NSString * imageName;//Icon image.
@property (nonatomic) NSString * className;//Sprite builder class.
@property (nonatomic) NSString * baseClass;//Actual runtime class.
@property (nonatomic) NSString * viewController; //UI Control to control the values.
-(CCEffect<EffectProtocol>*)constructDefault;

@end



@interface EffectsManager : NSObject
+(NSArray*)effects;
+(EffectDescription*)effectByClassName:(NSString*)className;
@end
