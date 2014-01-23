//
//  CCNode+SKNode.m
//  SpriteBuilder
//
//  Created by Steffen Itterheim on 23/01/14.
//
//

#import "CCNode+SKNode.h"

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

-(void) setFrameSize:(CGSize)frameSize
{
	self.contentSize = frameSize;
}
-(CGSize) frameSize
{
	return self.contentSize;
}

-(void) setFrameSizeType:(CCSizeType)frameSizeType
{
	self.contentSizeType = frameSizeType;
}
-(CCSizeType) frameSizeType
{
	return self.contentSizeType;
}

-(void) setAlpha:(CGFloat)alpha
{
	self.opacity = 255.0 * alpha;
}
-(CGFloat) alpha
{
	return (CGFloat)self.opacity / 255.0;
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

@end
