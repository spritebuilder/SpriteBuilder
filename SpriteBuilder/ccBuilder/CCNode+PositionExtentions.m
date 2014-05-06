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

- (CGFloat)topInPoints
{
    return self.positionInPoints.y + (self.contentSizeInPoints.height * (1.0f - self.anchorPoint.y)) * self.scaleYInPoints;
}

- (void)setTopInPoints:(CGFloat)top {
    NSPoint point = ccp(self.positionInPoints.x, top - (self.contentSizeInPoints.height * (1.0f - self.anchorPoint.y)) * self.scaleYInPoints);
    point = [self convertPositionFromPoints:point type:self.positionType];
    self.position = point;
}



- (CGFloat)rightInPoints
{
    return self.positionInPoints.x + (self.contentSizeInPoints.width * (1.0f - self.anchorPoint.x)) * self.scaleXInPoints;
}

- (void)setRightInPoints:(CGFloat)right {
    NSPoint point = ccp(right - (self.contentSizeInPoints.width * (1.0f - self.anchorPoint.x)) * self.scaleXInPoints, self.positionInPoints.y);
    point = [self convertPositionFromPoints:point type:self.positionType];
    self.position = point;
}



- (CGFloat)bottomInPoints
{
    return self.positionInPoints.y - (self.contentSizeInPoints.height * self.anchorPoint.y) * self.scaleYInPoints;
}

- (void)setBottomInPoints:(CGFloat)bottom {
    NSPoint point = ccp(self.positionInPoints.x, bottom + (self.contentSizeInPoints.height * self.anchorPoint.y) * self.scaleYInPoints);
    point = [self convertPositionFromPoints:point type:self.positionType];
    self.position = point;
}



- (CGFloat)leftInPoints
{
    return self.positionInPoints.x - (self.contentSizeInPoints.width * self.anchorPoint.x) * self.scaleXInPoints;
}

- (void)setLeftInPoints:(CGFloat)left {
    NSPoint point = ccp(left + (self.contentSizeInPoints.width * self.anchorPoint.x) * self.scaleXInPoints, self.positionInPoints.y);
    point = [self convertPositionFromPoints:point type:self.positionType];
    self.position = point;
}



- (CGFloat)centerXInPoints
{
    return self.positionInPoints.x - (self.contentSizeInPoints.width * self.anchorPoint.x) * self.scaleXInPoints + (self.contentSizeInPoints.width / 2) * self.scaleXInPoints;
}

- (void)setCenterXInPoints:(CGFloat)centerXInPoints {
    NSPoint point = ccp(centerXInPoints + (self.contentSizeInPoints.width * self.anchorPoint.x + self.contentSizeInPoints.width / 2) * self.scaleXInPoints, self.positionInPoints.y);
    point = [self convertPositionFromPoints:point type:self.positionType];
    self.position = point;
}



- (CGFloat)centerYInPoints
{
    return self.positionInPoints.y - (self.contentSizeInPoints.height * self.anchorPoint.y) * self.scaleYInPoints + (self.contentSizeInPoints.height / 2) * self.scaleYInPoints;
}

- (void)setCenterYInPoints:(CGFloat)centerYInPoints {
    NSPoint point = ccp(self.positionInPoints.x, centerYInPoints + (self.contentSizeInPoints.height * self.anchorPoint.y + self.contentSizeInPoints.height / 2) * self.scaleYInPoints);
    point = [self convertPositionFromPoints:point type:self.positionType];
    self.position = point;
}

@end
