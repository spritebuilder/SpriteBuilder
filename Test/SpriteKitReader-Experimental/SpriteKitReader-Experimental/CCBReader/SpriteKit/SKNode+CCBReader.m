//
//  SKNode+CCBReader.m
//  SpriteKitReader-Experimental
//
//  Created by Steffen Itterheim on 09/01/14.
//  Copyright (c) 2014 Steffen Itterheim. All rights reserved.
//

#import "SKNode+CCBReader.h"
#import "CCBSpriteKitMacros.h"

const NSString* kNodeUserObjectKey = @"CCBReader:UserObject";

@implementation SKNode (CCBReader)

-(void) setUserObject:(id)userObject
{
	if (self.userData == nil)
	{
		self.userData = [NSMutableDictionary dictionary];
	}

	if (userObject)
	{
		[self.userData setObject:userObject forKey:kNodeUserObjectKey];
	}
	else
	{
		[self.userData removeObjectForKey:kNodeUserObjectKey];
	}
}
-(id) userObject
{
	return [self.userData objectForKey:kNodeUserObjectKey];
}

-(CGSize) contentSize
{
	return self.frame.size;
}

-(void) setRotation:(CGFloat)rotation
{
	self.zRotation = rotation;
}
-(CGFloat) rotation
{
	return self.zRotation;
}

-(void) setSkewX:(CGFloat)skewX
{
}
-(CGFloat) skewX
{
	return 0.0;
}

-(void) setSkewY:(CGFloat)skewY
{
}
-(CGFloat) skewY
{
	return 0.0;
}

-(void) setVisible:(BOOL)visible
{
	self.hidden = !visible;
}
-(BOOL) visible
{
	return !self.hidden;
}

-(void) setPositionType:(CCPositionType)positionType
{
	NOTIMPLEMENTED();
}
-(CCPositionType) positionType
{
	CCPositionType type;
	type.xUnit = 0;
	type.yUnit = 0;
	type.corner = 0;
	return type;
}

-(void) setSpriteFrame:(SKTexture *)spriteFrame
{
	if ([self isKindOfClass:[SKSpriteNode class]])
	{
		SKSpriteNode* sprite = (SKSpriteNode*)self;
		sprite.texture = spriteFrame;
	}
}
-(SKTexture*)spriteFrame
{
	if ([self isKindOfClass:[SKSpriteNode class]])
	{
		SKSpriteNode* sprite = (SKSpriteNode*)self;
		return sprite.texture;
	}
	return nil;
}

-(CGFloat) scale
{
	return self.xScale;
}

@end
