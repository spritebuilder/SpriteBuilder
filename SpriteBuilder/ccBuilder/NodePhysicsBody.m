//
//  NodePhysicsBody.m
//  SpriteBuilder
//
//  Created by Viktor on 9/30/13.
//
//

#import "NodePhysicsBody.h"
#import "AppDelegate.h"

#define kCCBPhysicsMinimumDefaultCircleRadius 16

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

- (id) initWithSerialization:(id)ser
{
    self = [super init];
    if (!self) return NULL;
    
    // Shape
    _bodyShape = [[ser objectForKey:@"bodyShape"] intValue];
    _cornerRadius = [[ser objectForKey:@"cornerRadius"] floatValue];
    
    // Points
    NSArray* serPoints = [ser objectForKey:@"points"];
    NSMutableArray* points = [NSMutableArray array];
    for (NSArray* serPt in serPoints)
    {
        CGPoint pt = CGPointZero;
        pt.x = [[serPt objectAtIndex:0] floatValue];
        pt.y = [[serPt objectAtIndex:1] floatValue];
        [points addObject:[NSValue valueWithPoint:pt]];
    }
    
    self.points = points;
    
    // Basic physics props
    _dynamic = [[ser objectForKey:@"dynamic"] boolValue];
    _affectedByGravity = [[ser objectForKey:@"affectedByGravity"] boolValue];
    _allowsRotation = [[ser objectForKey:@"allowsRotation"] boolValue];
    
    _density = [[ser objectForKey:@"density"] floatValue];
    _friction = [[ser objectForKey:@"friction"] floatValue];
    _elasticity = [[ser objectForKey:@"elasticity"] floatValue];
    
    return self;
}

- (id) serialization
{
    NSMutableDictionary* ser = [NSMutableDictionary dictionary];
    
    // Shape
    [ser setObject:[NSNumber numberWithInt:_bodyShape] forKey:@"bodyShape"];
    [ser setObject:[NSNumber numberWithFloat:_cornerRadius] forKey:@"cornerRadius"];
    
    // Points
    NSMutableArray* serPoints = [NSMutableArray array];
    for (NSValue* val in _points)
    {
        CGPoint pt = [val pointValue];
        NSArray* serPt = [NSArray arrayWithObjects:
                       [NSNumber numberWithFloat:pt.x],
                       [NSNumber numberWithFloat:pt.y],
                       nil];
        [serPoints addObject:serPt];
    }
    [ser setObject:serPoints forKey:@"points"];
    
    // Basic physics props
    [ser setObject:[NSNumber numberWithBool:_dynamic] forKey:@"dynamic"];
    [ser setObject:[NSNumber numberWithBool:_affectedByGravity] forKey:@"affectedByGravity"];
    [ser setObject:[NSNumber numberWithBool:_allowsRotation] forKey:@"allowsRotation"];
    
    [ser setObject:[NSNumber numberWithFloat:_density] forKey:@"density"];
    [ser setObject:[NSNumber numberWithFloat:_friction] forKey:@"friction"];
    [ser setObject:[NSNumber numberWithFloat:_elasticity] forKey:@"elasticity"];
    
    return ser;
}

- (void) setupDefaultPolygonForNode:(CCNode*) node
{
    _bodyShape = kCCBPhysicsBodyShapePolygon;
    self.cornerRadius = 0;
    
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

- (void) setupDefaultCircleForNode:(CCNode*) node
{
    _bodyShape = kCCBPhysicsBodyShapeCircle;
    
    float radius = max(node.contentSize.width/2, node.contentSize.height/2);
    if (radius < kCCBPhysicsMinimumDefaultCircleRadius) radius = kCCBPhysicsMinimumDefaultCircleRadius;
    
    self.cornerRadius = radius;
    
    self.points = [NSArray arrayWithObject:[NSValue valueWithPoint:CGPointZero]];
}

- (void) setBodyShape:(int)bodyShape
{
    if (bodyShape == _bodyShape) return;
    
    [[AppDelegate appDelegate] saveUndoStateWillChangeProperty:@"*P*bodyShape"];
    _bodyShape = bodyShape;
    
    if (bodyShape == kCCBPhysicsBodyShapePolygon)
    {
        [self setupDefaultPolygonForNode:[AppDelegate appDelegate].selectedNode];
    }
    else if (bodyShape == kCCBPhysicsBodyShapeCircle)
    {
        [self setupDefaultCircleForNode:[AppDelegate appDelegate].selectedNode];
    }
}

- (void) setCornerRadius:(float)cornerRadius
{
    [[AppDelegate appDelegate] saveUndoStateWillChangeProperty:@"*P*cornerRadius"];
    _cornerRadius = cornerRadius;
}

- (void) setPoints:(NSArray *)points
{
    if (points == _points) return;
    [_points release];
    _points = [points retain];
}

- (void) setDynamic:(BOOL)dynamic
{
    [[AppDelegate appDelegate] saveUndoStateWillChangeProperty:@"*P*dynamic"];
    _dynamic = dynamic;
}

- (void) setAffectedByGravity:(BOOL)affectedByGravity
{
    [[AppDelegate appDelegate] saveUndoStateWillChangeProperty:@"*P*affectedByGravity"];
    _affectedByGravity = affectedByGravity;
}

- (void) setAllowsRotation:(BOOL)allowsRotation
{
    [[AppDelegate appDelegate] saveUndoStateWillChangeProperty:@"*P*allowsRotation"];
    _allowsRotation = allowsRotation;
}

- (void) setDensity:(float)density
{
    [[AppDelegate appDelegate] saveUndoStateWillChangeProperty:@"*P*density"];
    _density = density;
}

- (void) setFriction:(float)friction
{
    [[AppDelegate appDelegate] saveUndoStateWillChangeProperty:@"*P*friction"];
    _friction = friction;
}

- (void) setElasticity:(float)elasticity
{
    [[AppDelegate appDelegate] saveUndoStateWillChangeProperty:@"*P*elasticity"];
    _elasticity = elasticity;
}

- (void) dealloc
{
    self.points = NULL;
    [super dealloc];
}

@end
