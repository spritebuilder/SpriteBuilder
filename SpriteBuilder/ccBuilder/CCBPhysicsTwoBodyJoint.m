//
//  CCBPhysicsTwoBodyJoint.m
//  SpriteBuilder
//
//  Created by John Twigg on 3/6/14.
//
//

#import "CCBPhysicsTwoBodyJoint.h"
#import "GeometryUtil.h"
#import "AppDelegate.h"
#import "CCNode+NodeInfo.h"


@interface CCBPhysicsJoint()
-(void)updateSelectionUI;
@end


const float kMargin = 8.0f/64.0f;
const float kEdgeRadius = 8.0f;

static const float kDefaultLength = 58.0f;


@interface CCBPhysicsTwoBodyJoint()
{
    CCSprite        * anchorHandleA;
    CCSprite        * anchorHandleB;
    
    CCSpriteFrame   * distanceJointFrame;
    CCSpriteFrame   * distanceJointFrameSel;
    
}
@end

@implementation CCBPhysicsTwoBodyJoint
@synthesize anchorB;


-(void)setupBody
{
    jointBody = [CCSprite9Slice spriteWithImageNamed:@"joint-distance.png"];
    CCSizeType sizeType;
    sizeType.heightUnit = CCSizeUnitUIPoints;
    sizeType.widthUnit = CCSizeUnitUIPoints;
    jointBody.contentSizeType = sizeType;
    [scaleFreeNode addChild:jointBody];
    
    anchorHandleA = [CCSprite spriteWithImageNamed:@"joint-anchor.png"];
    anchorHandleB = [CCSprite spriteWithImageNamed:@"joint-anchor.png"];
    
    [scaleFreeNode addChild:anchorHandleA];
    [scaleFreeNode addChild:anchorHandleB];

    
    distanceJointFrameSel = [CCSpriteFrame frameWithImageNamed:@"joint-distance-sel.png"];
    distanceJointFrame    = [CCSpriteFrame frameWithImageNamed:@"joint-distance.png"];
}


-(float)worldLength
{
    if(self.bodyA && self.bodyB)
    {
        CGPoint worldPosA = [self.bodyA convertToWorldSpace:self.anchorA];
        CGPoint worldPosB = [self.bodyB convertToWorldSpace:self.anchorB];
        
        float distance = ccpDistance(worldPosA, worldPosB);
        return distance * [CCDirector sharedDirector].contentScaleFactor;
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


-(void)updateSelectionUI
{
    //If selected, display selected sprites.
    if(selectedBodyHandle & (1 << EntireJoint))
    {
        jointBody.spriteFrame = distanceJointFrameSel;
    }
    else //Unseleted
    {
        jointBody.spriteFrame = distanceJointFrame;
    }

    [super updateSelectionUI];
}

-(void)updateRenderBody
{

    float length = [self worldLength];
    jointBody.contentSize = CGSizeMake(length + 2.0f * kEdgeRadius, kEdgeRadius * 2.0f);
    jointBody.marginLeft = kMargin ;
    jointBody.marginRight = kMargin ;
    jointBody.marginBottom = 0.0;
    jointBody.marginTop = 0.0;
    jointBody.scale = 1.0f;
    
    jointBody.anchorPoint = ccp(kEdgeRadius/jointBody.contentSize.width, 0.5f);
    self.rotation = [self rotation];

    
    
    //Anchor B
    anchorHandleB.position = ccpMult(ccp(length,0),[CCDirector sharedDirector].UIScaleFactor);
    
    
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



-(JointHandleType)hitTestJointHandle:(CGPoint)worlPos
{
    {
        CGPoint pointA = [anchorHandleA convertToNodeSpaceAR:worlPos];
        pointA = ccpAdd(pointA, ccp(0,3.0f * [CCDirector sharedDirector].UIScaleFactor));
        if(ccpLength(pointA) < 4.0f* [CCDirector sharedDirector].UIScaleFactor)
        {
            return BodyAnchorA;
        }
    }
    
    {
        CGPoint pointB = [anchorHandleB convertToNodeSpaceAR:worlPos];
        pointB = ccpAdd(pointB, ccp(0,3.0f * [CCDirector sharedDirector].UIScaleFactor));
        if(ccpLength(pointB) < 4.0f* [CCDirector sharedDirector].UIScaleFactor)
        {
            return BodyAnchorB;
        }
    }
    
    
    return [super hitTestJointHandle:worlPos];;
}


- (BOOL)hitTestWithWorldPos:(CGPoint)pos
{
    CGPoint anchorAWorldpos = [anchorHandleA convertToWorldSpace:CGPointZero];
    CGPoint anchorBWorldpos = [anchorHandleB convertToWorldSpace:CGPointZero];
    
    
    float distance = [GeometryUtil distanceFromLineSegment:anchorAWorldpos b:anchorBWorldpos c:pos];
    
    if(distance < 8.0f)
    {
        return YES;
    }
    
    return NO;
    
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



-(void)setAnchorB:(CGPoint)lAnchorB
{
    anchorB = lAnchorB;
}

-(void)setBodyHandle:(CGPoint)worldPos bodyType:(JointHandleType)bodyType
{
    if(bodyType == BodyAnchorB)
    {
        CGPoint newPosition = [self.bodyB convertToNodeSpace:worldPos];
        self.anchorB = newPosition;
        [[AppDelegate appDelegate] refreshProperty:@"anchorB"];
        
    }
    
    [super setBodyHandle:worldPos bodyType:bodyType];
}

-(float)outletLateralOffset
{
    return 58.0/2.0f;
}


@end
