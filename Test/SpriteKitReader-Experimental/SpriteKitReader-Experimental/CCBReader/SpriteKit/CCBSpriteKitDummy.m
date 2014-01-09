//
//  CCBSpriteKitDummy.m
//  SpriteKitReader-Experimental
//
//  Created by Steffen Itterheim on 09/01/14.
//  Copyright (c) 2014 Steffen Itterheim. All rights reserved.
//

#import "CCBSpriteKitDummy.h"
#import "CCBSpriteKitMacros.h"

@implementation CCBSpriteKitDummy

#pragma mark Director

+(instancetype) sharedDirector
{
	NOTIMPLEMENTED();
	return nil;
}

-(CGFloat) UIScaleFactor
{
	return 1.0;
}

#pragma mark Action Manager

-(CCBSpriteKitDummyAction*) getActionByTag:(int)tag target:(id)target
{
	NOTIMPLEMENTED();
	return nil;
}

-(void) removeActionByTag:(int)tag target:(id)target
{
	NOTIMPLEMENTED();
}

#pragma mark Sprite Frame

+(instancetype) sharedSpriteFrameCache
{
	NOTIMPLEMENTED();
	return nil;
}

-(void) loadSpriteFrameLookupDictionaryFromFile:(NSString*)file
{
	NOTIMPLEMENTED();
}

#pragma mark ObjectAL

+(instancetype) sharedInstance
{
	NOTIMPLEMENTED();
	return nil;
}

-(void) playEffect:(NSString*)soundFile volume:(CGFloat)gain pitch:(CGFloat)pitch pan:(CGFloat)pan loop:(BOOL)loop
{
	NOTIMPLEMENTED();
}

@end


#pragma mark Actions

@implementation CCBSpriteKitDummyAction

+(instancetype) action
{
	NOTIMPLEMENTED();
	return nil;
}

+(instancetype) actionWithAction:(CCBSpriteKitDummyAction*)action
{
	NOTIMPLEMENTED();
	return nil;
}

+(instancetype) actionWithAction:(CCBSpriteKitDummyAction*)action rate:(CGFloat)rate
{
	NOTIMPLEMENTED();
	return nil;
}

+(instancetype) actionWithAction:(CCBSpriteKitDummyAction*)action period:(CGFloat)period
{
	NOTIMPLEMENTED();
	return nil;
}

+(instancetype) actionOne:(CCBSpriteKitDummyAction*)one two:(CCBSpriteKitDummyAction*)two
{
	NOTIMPLEMENTED();
	return nil;
}

+(instancetype) actionWithArray:(NSArray*)array
{
	NOTIMPLEMENTED();
	return nil;
}

+(instancetype) actionWithDuration:(CCTime)duration
{
	NOTIMPLEMENTED();
	return nil;
}

+(instancetype) actionWithDuration:(CCTime)duration opacity:(uint8_t)opacity
{
	NOTIMPLEMENTED();
	return nil;
}

+(instancetype) actionWithDuration:(CCTime)duration color:(CCColor*)color
{
	NOTIMPLEMENTED();
	return nil;
}

+(instancetype) actionWithDuration:(double)duration position:(CGPoint)position
{
	NOTIMPLEMENTED();
	return nil;
}

+(instancetype) actionWithDuration:(double)duration scaleX:(CGFloat)scaleX scaleY:(CGFloat)scaleY
{
	NOTIMPLEMENTED();
	return nil;
}

+(instancetype) actionWithDuration:(double)duration skewX:(CGFloat)skewX skewY:(CGFloat)skewY
{
	NOTIMPLEMENTED();
	return nil;
}

+(instancetype) actionWithTarget:(id)target selector:(SEL)selector
{
	NOTIMPLEMENTED();
	return nil;
}

-(instancetype) initWithDuration:(double)duration
{
	NOTIMPLEMENTED();
	return nil;
}

-(void) startWithTarget:(id)target
{
	NOTIMPLEMENTED();
}

@end
