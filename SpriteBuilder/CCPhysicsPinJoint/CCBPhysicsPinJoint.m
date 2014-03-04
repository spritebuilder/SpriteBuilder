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



@interface CCBPhysicsPinJoint()
{
    CCSprite9Slice  * jointBody;
    CCSprite        * anchorHandleA;
    CCSprite        * anchorHandleB;
}


@end

@implementation CCBPhysicsPinJoint


- (id) init
{
    self = [super init];
    if (!self)
    {
        return NULL;
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
    
    
}

-(float)length
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
    float length = [self length];
    
    jointBody.contentSize = CGSizeMake(length + 2.0f * kEdgeRadius, kEdgeRadius * 2.0f);
    jointBody.anchorPoint = ccp(kEdgeRadius/jointBody.contentSize.width, 0.5f);
    self.rotation = [self rotation];
    
    //Anchor B
    anchorHandleB.position = ccpMult(ccp(length,0),1/[CCDirector sharedDirector].contentScaleFactor);
    
}

-(void)visit
{
    [self updateRenderBody];
    [super visit];
}


-(void)setBodyB:(CCNode *)aBodyB
{
    [super setBodyB:aBodyB];
    [self setAnchorFromBodyB];
}

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



-(BodyIndex)hitTestBodyAnchor:(CGPoint)worlPos
{
    
    {
        CGPoint pointA = [anchorHandleA convertToNodeSpaceAR:worlPos];
        pointA = ccpAdd(pointA, ccp(0,5.0f));
        if(ccpLength(pointA) < 8.0f)
        {
            return BodyIndexA;
        }
    }
    
    {
        CGPoint pointB = [anchorHandleB convertToNodeSpaceAR:worlPos];
        pointB = ccpAdd(pointB, ccp(0,5.0f));
        if(ccpLength(pointB) < 8.0f)
        {
            return BodyIndexB;
        }
    }
 
    return BodyIndexUnknown;
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

-(void)setBodyAnchor:(CGPoint)worldPos bodyType:(BodyIndex)bodyType
{
    if(bodyType == BodyIndexB)
    {
        CGPoint newPosition = [self.bodyB convertToNodeSpace:worldPos];
        self.anchorB = newPosition;
        [[AppDelegate appDelegate] refreshProperty:@"anchorB"];

    }
    [super setBodyAnchor:worldPos bodyType:bodyType];
}



@end
