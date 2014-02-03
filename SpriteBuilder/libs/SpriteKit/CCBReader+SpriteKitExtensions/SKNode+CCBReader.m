/*
 * SpriteBuilder: http://www.spritebuilder.org
 *
 * Copyright (c) 2014 Apportable Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

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

-(void) setContentSize:(CGSize)contentSize
{
	// does nothing
}
-(CGSize) contentSize
{
	return self.frame.size;
}

-(void) setContentSizeType:(CCSizeType)contentSizeType
{
	// does nothing
}
-(CCSizeType) contentSizeType
{
	return CCSizeTypeMake(CCSizeUnitPoints, CCSizeUnitPoints);
}

-(void) setRotation:(CGFloat)rotation
{
	self.zRotation = CC_DEGREES_TO_RADIANS(-rotation);
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

-(void) setScaleX:(CGFloat)scaleX
{
	self.xScale = scaleX;
}
-(void) setScaleY:(CGFloat)scaleY
{
	self.yScale = scaleY;
}
-(CGFloat) scale
{
	return self.xScale;
}

-(void) ccb_setAnchorPoint:(CGPoint)anchorPoint
{
	if ([self isKindOfClass:[SKSpriteNode class]] ||
		[self isKindOfClass:[SKScene class]] ||
		[self isKindOfClass:[SKVideoNode class]])
	{
		// FIXME: infinite recursion
		//((SKScene*)self).anchorPoint = anchorPoint;
	}
}
/*
-(CGPoint) ccb_anchorPoint
{
	if ([self isKindOfClass:[SKSpriteNode class]] ||
		[self isKindOfClass:[SKScene class]] ||
		[self isKindOfClass:[SKVideoNode class]])
	{
		return ((SKScene*)self).anchorPoint;
	}
	
	return CGPointZero;
}
 */

-(void) setValue:(id)value forKey:(NSString *)key
{
	[super setValue:value forKey:key];
	
	/*
	if ([key isEqualToString:@"color"])
	{
		NSLog(@"NODE COLOR: %@ - READER COLOR: %@", [self performSelector:NSSelectorFromString(@"color")], value);
	}
	 */
}

-(void) setValue:(id)value forUndefinedKey:(NSString *)key
{
	NSLog(@"IGNORED: %@ undefined key '%@' for value: %@", NSStringFromClass([self class]), key, value);
}

@end
