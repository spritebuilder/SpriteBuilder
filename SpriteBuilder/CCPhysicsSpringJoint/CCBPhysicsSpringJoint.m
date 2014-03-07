//
//  CCBPPhysicsSpringJoint.m
//  SpriteBuilder
//
//  Created by John Twigg
//
//

#import "CCBPhysicsSpringJoint.h"
#import "AppDelegate.h"



@interface CCBPhysicsJoint()
-(void)updateSelectionUI;
@end

@implementation CCBPhysicsSpringJoint
{
    CCSprite9Slice  * jointBody;

    CCSprite        * restLengthHandle;
    CCSprite9Slice  * restLengthHandleBody;

}


- (id) init
{
    self = [super init];
    if (self)
    {
        self.stiffness = 4.0f;
        self.damping = 1.0f;
    }
    
    return self;
}


-(void)setupBody
{
    [super setupBody];
    
    jointBody = [CCSprite9Slice spriteWithImageNamed:@"joint-distance.png"];
    jointBody.marginLeft = kMargin;
    jointBody.marginRight = kMargin;
    jointBody.marginBottom = 0.0;
    jointBody.marginTop = 0.0;
    jointBody.scale = 1.0;
    
    
    [scaleFreeNode addChild:jointBody];
    
    
    restLengthHandle = [CCSprite spriteWithImageNamed:@"joint-distance-handle-short.png"];
    restLengthHandle.anchorPoint = ccp(0.5f, 0.0f);
    [scaleFreeNode addChild:restLengthHandle];
    
    
    
    restLengthHandleBody = [CCSprite9Slice spriteWithImageNamed:@"joint-distance-slide.png"];
    restLengthHandleBody.marginLeft = 0.0f;
    restLengthHandleBody.marginRight = kMargin;
    restLengthHandleBody.marginBottom = 0.0;
    restLengthHandleBody.marginTop = 0.0;
    restLengthHandleBody.scale = 1.0;
    restLengthHandleBody.anchorPoint = ccp(0.0f,0.5f);
    [scaleFreeNode addChild:restLengthHandleBody];
    
}

-(void)updateRenderBody
{
    [super updateRenderBody];
    float length = [self worldLength];
    
    jointBody.contentSize = CGSizeMake(length + 2.0f * kEdgeRadius, kEdgeRadius * 2.0f);
    jointBody.anchorPoint = ccp(kEdgeRadius/jointBody.contentSize.width, 0.5f);
    self.rotation = [self rotation];
    
    
    restLengthHandle.position = ccpMult(ccp(length *  self.restLength / [self localLength], kEdgeRadius - 1.0f),1/[CCDirector sharedDirector].contentScaleFactor);
    
    restLengthHandleBody.contentSize = CGSizeMake(length *  self.restLength / [self localLength] + kEdgeRadius, kEdgeRadius * 2.0f);
    
}

-(void)visit
{
    [self updateRenderBody];
    [super visit];
}



-(JointHandleType)hitTestJointHandle:(CGPoint)worlPos
{
    
    
    {
        CGPoint pointMin = [restLengthHandle convertToNodeSpaceAR:worlPos];
        pointMin = ccpSub(pointMin, ccp(0,2.0f));
        if(ccpLength(pointMin) < 7.0f)
        {
            return RestLengthHandle;
        }
    }
    
    return [super hitTestJointHandle:worlPos];;
}

-(void)updateSelectionUI
{
    //If selected, display selected sprites.
    if(selectedBodyHandle & (1 << EntireJoint))
    {
        jointBody.spriteFrame = [CCSpriteFrame frameWithImageNamed:@"joint-distance-sel.png"];
        
        if(restLengthHandle.parent == nil)
            [scaleFreeNode addChild:restLengthHandle];
    }
    else //Unseleted
    {
        jointBody.spriteFrame = [CCSpriteFrame frameWithImageNamed:@"joint-distance.png"];
        
        if(restLengthHandle.parent != nil)
            [restLengthHandle removeFromParentAndCleanup:NO];
    }
    
    
    if(selectedBodyHandle & (1 << RestLengthHandle))
    {
        restLengthHandleBody.spriteFrame = [CCSpriteFrame frameWithImageNamed:@"joint-distance-slide-sel.png"];
    }
    else
    {
        restLengthHandleBody.spriteFrame = [CCSpriteFrame frameWithImageNamed:@"joint-distance-slide.png"];
    }
    
    [super updateSelectionUI];
}



#pragma mark - Properties -


-(void)setAnchorA:(CGPoint)lAnchorA
{
    [super setAnchorA:lAnchorA];
    //refresh max mins
    self.restLength = self.restLength;
    
}


-(void)setAnchorB:(CGPoint)lAnchorB
{
    [super setAnchorB:lAnchorB];
    //refresh max mins
    self.restLength = self.restLength;
}



-(void)setBodyHandle:(CGPoint)worldPos bodyType:(JointHandleType)bodyType
{
    if(bodyType == RestLengthHandle)
    {
        CGPoint localPoint = [self convertToNodeSpace:worldPos];
        self.restLength =  localPoint.x;
        [[AppDelegate appDelegate] refreshProperty:@"restLength"];
    }
    
    [super setBodyHandle:worldPos bodyType:bodyType];
}

-(void)setBodyA:(CCNode *)lBodyA
{
    [super setBodyA:lBodyA];
    self.restLength = [self worldLength];
}

-(void)setBodyB:(CCNode *)lBodyB
{
    [super setBodyB:lBodyB];
    self.restLength = [self worldLength];
}


-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if(object == self.bodyB)
    {

    
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}


@end
