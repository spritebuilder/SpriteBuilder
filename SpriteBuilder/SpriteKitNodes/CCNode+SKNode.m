//
//  CCNode+SKNode.m
//  SpriteBuilder
//
//  Created by Steffen Itterheim on 23/01/14.
//
//

#import "CCNode+SKNode.h"
#import "CCNodeColor.h"
#import "CCDirector.h"
#import "CCNode_Private.h"

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

-(void) setNodeHidden:(BOOL)hidden
{
	self.visible = !hidden;
}
-(BOOL) nodeHidden
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

#pragma mark Relative Position

-(CGPoint) positionRelativeToParent:(CGPoint)position
{
	if (_parent == nil)
	{
		//NSLog(@"'%@' %p has no parent", self.name, self);
		return self.position;
	}
	
	CGPoint newPosition = position;
	CGSize parentSizeInPoints = [_parent convertContentSizeToPoints:_parent.contentSize type:_parent.contentSizeType];
	CGPoint parentAnchorInPoints = CGPointMake(parentSizeInPoints.width * _parent.anchorPoint.x, parentSizeInPoints.height * _parent.anchorPoint.y);
	
	switch (self.positionType.xUnit)
	{
		case CCPositionUnitPoints:
			newPosition.x += parentAnchorInPoints.x;
			break;
		case CCPositionUnitUIPoints:
			newPosition.x += parentAnchorInPoints.x * [CCDirector sharedDirector].UIScaleFactor;
			break;
		case CCPositionUnitNormalized:
			// defined as "% of parent container" so no adjustment needed
			break;
			
		default:
			break;
	}

	switch (self.positionType.yUnit)
	{
		case CCPositionUnitPoints:
			newPosition.y += parentAnchorInPoints.y;
			break;
		case CCPositionUnitUIPoints:
			newPosition.y += parentAnchorInPoints.y * [CCDirector sharedDirector].UIScaleFactor;
			break;
		case CCPositionUnitNormalized:
			// defined as "% of parent container" so no adjustment needed
			break;
			
		default:
			break;
	}

	//NSLog(@"'%@' %p pos: %@ new: %@ p-anch: %@", self.name, self, NSStringFromPoint(position), NSStringFromPoint(newPosition), NSStringFromPoint(parentAnchorInPoints));
	return newPosition;
}

-(void) didMoveToParent
{
	// update position based on parent values
	[self positionRelativeToParent:_position];
	
	// do so recursively for all child nodes
	for (CCNode* node in _children)
	{
		[node positionRelativeToParent:node.position];
	}
}

#pragma mark z Position

/*
@dynamic zPosition;
-(void) setZPosition:(CGFloat)z
{
	// assign to vertexZ so we can keep the floating point aspect (SK zPosition is a CGFloat)
	self.vertexZ = z;
	// apply z to zOrder so that draw order inside SB is updated
	self.zOrder = (NSInteger)z;
}

-(CGFloat) zPosition
{
	return (CGFloat)self.vertexZ;
}
*/

@end
