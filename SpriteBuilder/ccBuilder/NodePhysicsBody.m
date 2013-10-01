//
//  NodePhysicsBody.m
//  SpriteBuilder
//
//  Created by Viktor on 9/30/13.
//
//

#import "NodePhysicsBody.h"

@implementation NodePhysicsBody

- (id) initWithNode:(CCNode*) node
{
    self = [super init];
    if (!self) return NULL;
    
    [self setupDefaultPolygonForNode:node];
    
    _dynamic = YES;
    _affectedByGravity = YES;
    _allowsRotation = YES;
    
    _density = 1.0f;
    _friction = 0.3f;
    _elasticity = 0.3f;
    
    return self;
}

- (void) setupDefaultPolygonForNode:(CCNode*) node
{
    _bodyShape = kCCBPhysicsBodyShapePolygon;
    
    float w = node.contentSize.width;
    float h = node.contentSize.height;
    CGPoint anchorPoint = node.anchorPoint;
    
    if (w == 0)
    {
        w = 32;
        anchorPoint = ccp(0.5f, 0.5f);
    }
    if (h == 0)
    {
        h = 32;
        anchorPoint = ccp(0.5f, 0.5f);
    }
    
    // Calculate corners
    CGPoint a = ccp((1.0f - anchorPoint.x) * w, (1.0f - anchorPoint.y) * h);
    CGPoint b = ccp(- anchorPoint.x * w, (1.0f - anchorPoint.y) * h);
    CGPoint c = ccp(- anchorPoint.x * w, - anchorPoint.y * h);
    CGPoint d = ccp((1.0f - anchorPoint.x) * w, - anchorPoint.y * h);
    
    self.points = [NSArray arrayWithObjects:
                   [NSValue valueWithPoint:a],
                   [NSValue valueWithPoint:b],
                   [NSValue valueWithPoint:c],
                   [NSValue valueWithPoint:d],
                   nil];
}

- (void) dealloc
{
    self.points = NULL;
    [super dealloc];
}

@end
