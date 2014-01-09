//
//  CCBSpriteKitDummy.h
//  SpriteKitReader-Experimental
//
//  Created by Steffen Itterheim on 09/01/14.
//  Copyright (c) 2014 Steffen Itterheim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCBSpriteKitCompatibility.h"

@class CCBSpriteKitDummyAction;

@interface CCBSpriteKitDummy : NSObject

+(instancetype) sharedDirector;
@property CGSize designSize;
@property CCBSpriteKitDummy* actionManager;
@property (readonly) CGFloat UIScaleFactor;

-(CCBSpriteKitDummyAction*) getActionByTag:(int)tag target:(id)target;
-(void) removeActionByTag:(int)tag target:(id)target;

+(instancetype) sharedSpriteFrameCache;
-(void) loadSpriteFrameLookupDictionaryFromFile:(NSString*)file;

+(instancetype) sharedInstance;
-(void) playEffect:(NSString*)soundFile volume:(CGFloat)gain pitch:(CGFloat)pitch pan:(CGFloat)pan loop:(BOOL)loop;

@end

@interface CCBSpriteKitDummyAction : SKAction
{
	@protected
	id _target;
	id _originalTarget;
	double _elapsed;
	double _firstTick;
}

+(instancetype) action;
+(instancetype) actionWithAction:(CCBSpriteKitDummyAction*)action;
+(instancetype) actionWithAction:(CCBSpriteKitDummyAction*)action rate:(CGFloat)rate;
+(instancetype) actionWithAction:(CCBSpriteKitDummyAction*)action period:(CGFloat)period;
+(instancetype) actionOne:(CCBSpriteKitDummyAction*)one two:(CCBSpriteKitDummyAction*)two;
+(instancetype) actionWithArray:(NSArray*)array;
+(instancetype) actionWithDuration:(double)duration;
+(instancetype) actionWithDuration:(double)duration opacity:(uint8_t)opacity;
+(instancetype) actionWithDuration:(double)duration color:(SKColor*)color;
+(instancetype) actionWithDuration:(double)duration position:(CGPoint)position;
+(instancetype) actionWithDuration:(double)duration scaleX:(CGFloat)scaleX scaleY:(CGFloat)scaleY;
+(instancetype) actionWithDuration:(double)duration skewX:(CGFloat)skewX skewY:(CGFloat)skewY;
+(instancetype) actionWithTarget:(id)target selector:(SEL)selector;
-(instancetype) initWithDuration:(double)duration;
-(void) startWithTarget:(id)target;

@property int tag;
@property id target;
@property id originalTarget;
@property id inner;
@property CGFloat rotationalSkewX;
@property CGFloat rotationalSkewY;

@end
