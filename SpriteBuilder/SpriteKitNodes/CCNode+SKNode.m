//
//  CCNode+SKNode.m
//  SpriteBuilder
//
//  Created by Steffen Itterheim on 23/01/14.
//
//

#import "CCNode+SKNode.h"
#import "CCNodeColor.h"

@implementation CCNode (SKNode)

-(void) setValue:(id)value forUndefinedKey:(NSString *)key
{
	NSLog(@"%@: IGNORING undefined key '%@' - can't set value '%@'", NSStringFromClass([self class]), key, value);
}

-(id) valueForUndefinedKey:(NSString *)key
{
	NSLog(@"%@: IGNORING value for undefined key '%@' - returning nil", NSStringFromClass([self class]), key);
	return nil;
}

#pragma mark SKNode

-(void) setAlpha:(CGFloat)alpha
{
	NSLog(@"%@ alpha = %f", NSStringFromClass([self class]), alpha);
	self.opacity = alpha;
}
-(CGFloat) alpha
{
	return self.opacity;
}

// TODO: implement speed property
-(void) setSpeed:(CGFloat)speed
{
}
-(CGFloat) speed
{
	return 1.0;
}

-(void) setXScale:(CGFloat)xScale
{
	self.scaleX = xScale;
}
-(CGFloat) xScale
{
	return self.scaleX;
}

-(void) setYScale:(CGFloat)yScale
{
	self.scaleY = yScale;
}
-(CGFloat) yScale
{
	return self.scaleY;
}

-(void) setZRotation:(CGFloat)zRotation
{
	self.rotation = zRotation;
}
-(CGFloat) zRotation
{
	return self.rotation;
}

-(void) setHidden:(BOOL)hidden
{
	self.visible = !hidden;
}
-(BOOL) hidden
{
	return !self.visible;
}

#pragma mark SKSpriteNode

// TODO: implement color blend factor
-(void) setColorBlendFactor:(CGFloat)colorBlendFactor
{
}
-(CGFloat) colorBlendFactor
{
	return 1.0;
}

-(void) setSize:(CGSize)size
{
	self.contentSize = size;
}
-(CGSize) size
{
	return self.contentSize;
}

-(void) setSizeType:(CCSizeType)sizeType
{
	self.contentSizeType = sizeType;
}
-(CCSizeType) sizeType
{
	return self.contentSizeType;
}

@end
