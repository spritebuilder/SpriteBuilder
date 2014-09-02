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

////////////////////////////////////////////////////////////
//Effects should implement this protocol,

#import "NSArray+Query.h"

#define DESERIALIZE_PROPERTY(name, numberValue)\
[properties findFirst:^BOOL(NSDictionary * dict, int idx) {\
return [dict[@"name"] isEqualToString:[NSString stringWithUTF8String:#name]];\
} complete:^(NSDictionary * dict, int idx) {\
self.name = [dict[@"value"] numberValue];\
}];

#define SERIALIZE_PROPERTY(name, type)\
	@{@"name" : [NSString stringWithUTF8String: #name], @"type" : [NSString stringWithUTF8String: #type], @"value": @(self.name)}



@protocol EffectProtocol <NSObject>
@required
@property (nonatomic,readonly) EffectDescription * effectDescription;
@property (nonatomic) NSUInteger UUID;
+(CCEffect<EffectProtocol>*)defaultConstruct;
-(id)serialize;
-(void)deserialize:(NSArray*)properties;

@end

////////////////////////////////////////////////////////////
//Effect nodes (like CCsprite and CCEffectNode) should implement this.
@protocol CCEffectNodeProtocol <NSObject>
@required
@property (nonatomic,readonly) NSArray * effectDescriptors;
@property (nonatomic, assign) NSArray * effects;

-(void)addEffect:(CCEffect<EffectProtocol>*)effect;
-(void)removeEffect:(CCEffect<EffectProtocol>*)effect;

@end



////////////////////////////////////////////////////////////
//Helper
@interface CCNode (Effects)
-(CCEffect<EffectProtocol>*)findEffect:(NSUInteger)uuid;
@end

////////////////////////////////////////////////////////////
//Effect type descriptor.
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

////////////////////////////////////////////////////////////
//Effects Manager.
@interface EffectsManager : NSObject
+(NSArray*)effects;
+(EffectDescription*)effectByClassName:(NSString*)className;
@end
