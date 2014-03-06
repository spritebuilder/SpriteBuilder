//
//  CCBPhysicsPinJoint.m
//  SpriteBuilder
//
//  Created by John Twigg on 2/19/14.
//
//

#import "CCBPhysicsPinJoint.h"
#import "AppDelegate.h"
#import "GeometryUtil.h"

static const float kMargin = 8.0f/64.0f;
static const float kDefaultLength = 58.0f;


@interface CCBPhysicsJoint()
-(void)updateSelectionUI;
@end

@interface CCBPhysicsPinJoint()
{
    CCSprite9Slice  * jointBody;
    CCSprite        * anchorHandleA;
    CCSprite        * anchorHandleB;
    
    CCSprite        * minHandle;
    CCSprite9Slice  * minHandleBody;
    CCSprite        * maxHandle;
    CCSprite9Slice  * maxHandleBody;
    
}


@end

@implementation CCBPhysicsPinJoint
@synthesize minDistance;
@synthesize maxDistance;
@synthesize maxDistanceEnabled;
@synthesize minDistanceEnabled;
@synthesize anchorB;

- (id) init
{
    self = [super init];
    if (self)
    {
        self.minDistance = -INFINITY;
        self.maxDistance = INFINITY;

    }
    
    return self;
}


-(void)setupBody
{
    jointBody = [CCSprite9Slice spriteWithImageNamed:@"joint-distance.png"];
    jointBody.marginLeft = kMargin;
    jointBody.marginRight = kMargin;
    jointBody.marginBottom = 0.0;
    jointBody.marginTop = 0.0;
    jointBody.scale = 1.0;
    
    
    [scaleFreeNode addChild:jointBody];
    
    anchorHandleA = [CCSprite spriteWithImageNamed:@"joint-anchor.png"];
    anchorHandleB = [CCSprite spriteWithImageNamed:@"joint-anchor.png"];
    
    [scaleFreeNode addChild:anchorHandleA];
    [scaleFreeNode addChild:anchorHandleB];
    
    maxHandle = [CCSprite spriteWithImageNamed:@"joint-distance-handle-long.png"];
    maxHandle.anchorPoint = ccp(0.5f, 0.0f);
    minHandle = [CCSprite spriteWithImageNamed:@"joint-distance-handle-short.png"];
    minHandle.anchorPoint = ccp(0.5f, 0.0f);
    [scaleFreeNode addChild:maxHandle];
    [scaleFreeNode addChild:minHandle];
    
    
    maxHandleBody = [CCSprite9Slice spriteWithImageNamed:@"joint-distance-slide.png"];
    maxHandleBody.marginLeft = 0.0f;
    maxHandleBody.marginRight = kMargin;
    maxHandleBody.marginBottom = 0.0;
    maxHandleBody.marginTop = 0.0;
    maxHandleBody.scale = 1.0;
    maxHandleBody.anchorPoint = ccp(0.0f,0.5f);
    [scaleFreeNode addChild:maxHandleBody];
    
    
    minHandleBody = [CCSprite9Slice spriteWithImageNamed:@"joint-distance-slide.png"];
    minHandleBody.marginLeft = 0.0f;
    minHandleBody.marginRight = kMargin;
    minHandleBody.marginBottom = 0.0;
    minHandleBody.marginTop = 0.0;
    minHandleBody.scale = 1.0;
    minHandleBody.anchorPoint = ccp(0.0f,0.5f);
    [scaleFreeNode addChild:minHandleBody];

}

-(float)worldLength
{
    if(self.bodyA && self.bodyB)
    {
        CGPoint worldPosA = [self.bodyA convertToWorldSpace:self.anchorA];
        CGPoint worldPosB = [self.bodyB convertToWorldSpace:self.anchorB];
        
        float distance = ccpDistance(worldPosA, worldPosB);
        return distance;
    }
    
    return kDefaultLength;
}

-(float)localLength
{
 
    if(self.bodyA && self.bodyB)
    {
        CGPoint worldPosA = [self.bodyA convertToWorldSpace:self.anchorA];
        CGPoint worldPosB = [self.bodyB convertToWorldSpace:self.anchorB];

        CGPoint localPosA = [self convertToNodeSpace:worldPosA];
        CGPoint localPosB = [self convertToNodeSpace:worldPosB];
        
        float distance = ccpDistance(localPosA, localPosB);
        return distance;
    }
    
    return kDefaultLength;
}

-(float)rotation
{
    if(self.bodyA && self.bodyB)
    {
        CGPoint worldPosA = [self.bodyA convertToWorldSpace:self.anchorA];
        CGPoint worldPosB = [self.bodyB convertToWorldSpace:self.anchorB];
        
        CGPoint segment = ccpSub(worldPosB,worldPosA);
        float angleRad = atan2f(segment.y, segment.x);
        float angle = -kmRadiansToDegrees( angleRad);
        return  angle;
    }

    return 0.0f;
}

const float kEdgeRadius = 8.0f;
-(void)updateRenderBody
{
    float length = [self worldLength];
    
    jointBody.contentSize = CGSizeMake(length + 2.0f * kEdgeRadius, kEdgeRadius * 2.0f);
    jointBody.anchorPoint = ccp(kEdgeRadius/jointBody.contentSize.width, 0.5f);
    self.rotation = [self rotation];
    
    //Anchor B
    anchorHandleB.position = ccpMult(ccp(length,0),1/[CCDirector sharedDirector].contentScaleFactor);
    
    
    minHandle.position = ccpMult(ccp(length *  self.minDistance / [self localLength], kEdgeRadius - 1.0f),1/[CCDirector sharedDirector].contentScaleFactor);
    maxHandle.position = ccpMult(ccp(length *  self.maxDistance /[self localLength], kEdgeRadius - 1.0f),1/[CCDirector sharedDirector].contentScaleFactor);
    
    minHandleBody.contentSize = CGSizeMake(length *  self.minDistance / [self localLength] + kEdgeRadius, kEdgeRadius * 2.0f);
    maxHandleBody.contentSize = CGSizeMake(length *  self.maxDistance / [self localLength] + kEdgeRadius, kEdgeRadius * 2.0f);
 
}

-(void)visit
{
    [self updateRenderBody];
    [super visit];
}



-(JointHandleType)hitTestJointHandle:(CGPoint)worlPos
{
    {
        CGPoint pointA = [anchorHandleA convertToNodeSpaceAR:worlPos];
        pointA = ccpAdd(pointA, ccp(0,5.0f));
        if(ccpLength(pointA) < 8.0f)
        {
            return BodyAnchorA;
        }
    }
    
    {
        CGPoint pointB = [anchorHandleB convertToNodeSpaceAR:worlPos];
        pointB = ccpAdd(pointB, ccp(0,5.0f));
        if(ccpLength(pointB) < 8.0f)
        {
            return BodyAnchorB;
        }
    }
    
    {
        CGPoint pointMin = [maxHandle convertToNodeSpaceAR:worlPos];
        pointMin = ccpSub(pointMin, ccp(0,15.0f));
        if(ccpLength(pointMin) < 7.0f)
        {
            return MaxHandleType;
        }
    }

    {
        CGPoint pointMin = [minHandle convertToNodeSpaceAR:worlPos];
        pointMin = ccpSub(pointMin, ccp(0,2.0f));
        if(ccpLength(pointMin) < 7.0f)
        {
            return MinHandleType;
        }
    }
    
    return [super hitTestJointHandle:worlPos];;
}

- (BOOL)hitTestWithWorldPos:(CGPoint)pos
{
    CGPoint anchorAWorldpos = [anchorHandleA convertToWorldSpace:CGPointZero];
    CGPoint anchorBWorldpos = [anchorHandleB convertToWorldSpace:CGPointZero];
    

    float distance = [GeometryUtil distanceFromLineSegment:anchorAWorldpos b:anchorBWorldpos c:pos];

    if(distance < 7.0f)
    {
        return YES;
    }
    
    return NO;
    
}


-(void)updateSelectionUI
{
    //If selected, display selected sprites.
    if(selectedBodyHandle & (1 << EntireJoint))
    {
        jointBody.spriteFrame = [CCSpriteFrame frameWithImageNamed:@"joint-distance-sel.png"];
        
        
        if(maxHandle.parent == nil && self.maxDistanceEnabled)
            [scaleFreeNode addChild:maxHandle];

        
        if(minHandle.parent == nil && self.minDistanceEnabled)
            [scaleFreeNode addChild:minHandle];

    }
    else
    {
        jointBody.spriteFrame = [CCSpriteFrame frameWithImageNamed:@"joint-distance.png"];
        
        if(maxHandle.parent != nil)
        {
            [maxHandle removeFromParentAndCleanup:NO];
        }

        if(minHandle.parent != nil)
            [minHandle removeFromParentAndCleanup:NO];

    }
    
    [super updateSelectionUI];
}



#pragma mark - Properties -


-(void)setAnchorFromBodyB
{
    if(!self.bodyB)
    {
        self.anchorB = CGPointZero;
        [[AppDelegate appDelegate] refreshProperty:@"anchorB"];
        return;
    }
    
    CGPoint anchorBPositionNodePos = ccpAdd(self.position, ccp(kDefaultLength,0));
    
    CGPoint worldPos = [self.parent convertToWorldSpace:anchorBPositionNodePos];
    CGPoint lAnchorb = [self.bodyB convertToNodeSpace:worldPos];
    
    self.anchorB = lAnchorb;
    [[AppDelegate appDelegate] refreshProperty:@"anchorB"];
}


-(void)setBodyB:(CCNode *)aBodyB
{
    [super setBodyB:aBodyB];
    [self setAnchorFromBodyB];
}


-(void)setAnchorB:(CGPoint)lAnchorB
{
    anchorB = lAnchorB;
    //refresh max mins
    self.minDistance = self.minDistance;
    self.maxDistance = self.maxDistance;
}

-(void)setAnchorA:(CGPoint)lAnchorA
{
    [super setAnchorA:lAnchorA];
    //refresh max mins
    self.minDistance = self.minDistance;
    self.maxDistance = self.maxDistance;
    
}


-(void)setBodyHandle:(CGPoint)worldPos bodyType:(JointHandleType)bodyType
{
    if(bodyType == BodyAnchorB)
    {
        CGPoint newPosition = [self.bodyB convertToNodeSpace:worldPos];
        self.anchorB = newPosition;
        [[AppDelegate appDelegate] refreshProperty:@"anchorB"];
        
    }
    
    if(bodyType == MaxHandleType)
    {
        CGPoint localPoint = [self convertToNodeSpace:worldPos];
        self.maxDistance =  localPoint.x;
    }
    
    if(bodyType == MinHandleType)
    {
        CGPoint localPoint = [self convertToNodeSpace:worldPos];
        self.minDistance =  localPoint.x;
    }
    
    [super setBodyHandle:worldPos bodyType:bodyType];
}


-(float)minDistance
{
    return minDistance;
}

-(float)maxDistance
{
    return maxDistance;
}

-(void)setMinDistance:(float)lMinDistance
{
    minDistance = lMinDistance;
    
    if(self.isRunningInActiveScene)
    {
        if(minDistance > [self localLength])
            minDistance = [self localLength];
        
        if(minDistance < 0)
            minDistance = 0;
    }
    
    if(self.isRunningInActiveScene && !minDistanceEnabled )
    {
        [self willChangeValueForKey:@"minDistance"];
        minDistance = -INFINITY;
        [self didChangeValueForKey:@"minDistance"];
    }
    [[AppDelegate appDelegate] refreshProperty:@"minDistance"];
    
}


-(void)setMaxDistance:(float)lMaxDistance
{
    maxDistance = lMaxDistance;
    
    if(self.isRunningInActiveScene && maxDistance < [self localLength])
    {
        maxDistance = [self localLength];
    }
    
    if(self.isRunningInActiveScene && !maxDistanceEnabled)
    {
        [self willChangeValueForKey:@"maxDistance"];
        maxDistance = INFINITY;
        [self didChangeValueForKey:@"maxDistance"];
    }
    
    [[AppDelegate appDelegate] refreshProperty:@"maxDistance"];
}

-(BOOL)maxDistanceEnabled
{
    return maxDistanceEnabled;
}

-(void)setMaxDistanceEnabled:(BOOL)lMaxDistanceEnabled
{
    if(maxDistanceEnabled != lMaxDistanceEnabled)
    {
        maxDistanceEnabled = lMaxDistanceEnabled;
        
        if(maxDistanceEnabled)
        {
            maxDistance = [self localLength];
        }
        else
        {
            maxDistance = INFINITY;
        }
    }
}


-(BOOL)minDistanceEnabled
{
    return minDistanceEnabled;
}

-(void)setMinDistanceEnabled:(BOOL)lMinDistanceEnabled
{
    if(minDistanceEnabled != lMinDistanceEnabled)
    {
        minDistanceEnabled = lMinDistanceEnabled;
        
        if(minDistanceEnabled)
        {
            minDistance = [self localLength];
        }
        else
        {
            minDistance = -INFINITY;
        }
    }
}


-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if(object == self.bodyB)
    {
        self.minDistance = self.minDistance;
        self.maxDistance = self.maxDistance;
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}


@end
