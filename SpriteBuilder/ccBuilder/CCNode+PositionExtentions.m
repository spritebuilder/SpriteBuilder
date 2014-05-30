//
//  CCNode+PositionExtentions.m
//  SpriteBuilder
//
//  Created by Michael Daniels on 4/8/14.
//
//

#import "CCNode+PositionExtentions.h"

@implementation CCNode (PositionExtentions)

#pragma mark - Side Positions in Points

-(CGRect)rectInPoints
{
    CGSize size = self.contentSizeInPoints;
    return CGRectApplyAffineTransform(CGRectMake(0, 0, size.width, size.height), self.nodeToWorldTransform);
}

// I could swear that CoreGraphics had a CGVectorApplyTransform()...
static inline CGPoint
TransformDirection(CGAffineTransform t, CGPoint v)
{
  return ccp(t.a*v.x + t.c*v.y, t.b*v.x + t.d*v.y);
}

- (CGFloat)topInPoints
{
    return CGRectGetMaxY(self.rectInPoints);
}

- (void)setTopInPoints:(CGFloat)top {
		CGPoint delta = TransformDirection(self.parent.worldToNodeTransform, ccp(0, top - self.topInPoints));
		self.positionInPoints = ccpAdd(self.positionInPoints, delta);
}

- (CGFloat)rightInPoints
{
    return CGRectGetMaxX(self.rectInPoints);
}

- (void)setRightInPoints:(CGFloat)right {
		CGPoint delta = TransformDirection(self.parent.worldToNodeTransform, ccp(right - self.rightInPoints, 0));
		self.positionInPoints = ccpAdd(self.positionInPoints, delta);
}

- (CGFloat)bottomInPoints
{
    return CGRectGetMinY(self.rectInPoints);
}

- (void)setBottomInPoints:(CGFloat)bottom {
		CGPoint delta = TransformDirection(self.parent.worldToNodeTransform, ccp(0, bottom - self.bottomInPoints));
		self.positionInPoints = ccpAdd(self.positionInPoints, delta);
}

- (CGFloat)leftInPoints
{	
    return CGRectGetMinX(self.rectInPoints);
}

- (void)setLeftInPoints:(CGFloat)left {
		CGPoint delta = TransformDirection(self.parent.worldToNodeTransform, ccp(left - self.leftInPoints, 0));
		self.positionInPoints = ccpAdd(self.positionInPoints, delta);
}

- (CGFloat)centerXInPoints
{
    CGRect rect = self.rectInPoints;
    return (CGRectGetMinX(rect) + CGRectGetMaxX(rect))/2.0;
}

- (void)setCenterXInPoints:(CGFloat)centerXInPoints {
		CGPoint delta = TransformDirection(self.parent.worldToNodeTransform, ccp(centerXInPoints - self.centerXInPoints, 0));
		self.positionInPoints = ccpAdd(self.positionInPoints, delta);
}

- (CGFloat)centerYInPoints
{
    CGRect rect = self.rectInPoints;
    return (CGRectGetMinY(rect) + CGRectGetMaxY(rect))/2.0;
}

- (void)setCenterYInPoints:(CGFloat)centerYInPoints {
		CGPoint delta = TransformDirection(self.parent.worldToNodeTransform, ccp(0, centerYInPoints - self.centerYInPoints));
		self.positionInPoints = ccpAdd(self.positionInPoints, delta);
}

@end