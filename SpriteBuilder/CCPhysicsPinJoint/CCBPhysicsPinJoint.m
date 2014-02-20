//
//  CCBPhysicsPinJoint.m
//  SpriteBuilder
//
//  Created by John Twigg on 2/19/14.
//
//

#import "CCBPhysicsPinJoint.h"
#import "AppDelegate.h"

static const float kMargin = 0.25f;
static const float kDefaultLength = 32.0f;

@interface CCBPhysicsPinJoint()
{
    CCSprite9Slice  * jointBody;
    CCSprite        * anchorHandleA;
    CCSprite        * anchorHandleB;
}

-(void)removeObserverBody:(CCNode*)body;
-(void)addObserverBody:(CCNode*)body;

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
    jointBody.scale = 1.5;
    
    
    [scaleFreeNode addChild:jointBody];
    
    anchorHandleA = [CCSprite spriteWithImageNamed:@"joint-anchor.png"];
    anchorHandleB = [CCSprite spriteWithImageNamed:@"joint-anchor.png"];
    
    [scaleFreeNode addChild:anchorHandleA];
    [scaleFreeNode addChild:anchorHandleB];
    
    
}

-(float)length
{
    if(bodyB == nil)
    {
        return kDefaultLength;
    }
    
    return kDefaultLength;
}

const float kEdgeRadius = 4.0f;
-(void)updateRenderBody
{
    float length = [self length];
    
    self.contentSize = CGSizeMake(length + 2.0f * kEdgeRadius, kEdgeRadius * 2.0f);
    jointBody.anchorPoint = ccp(kEdgeRadius/length, 0.5f);
    
    
    //Anchor B
}

-(void)setPosition:(CGPoint)position
{
    [super setPosition:position];
    
    [self updateRenderBody];
    
    
}


-(void)setBodyA:(CCNode *)aBodyA
{
    [super setBodyA:aBodyA];
    [self updateRenderBody];
    
}



-(void)setBodyB:(CCNode *)aBodyB
{
    if(bodyB)
    {
        [self removeObserverBody:aBodyB];
    }
    
    [super setBodyB:aBodyB];
    
    
    [self setAnchorFromBodyB];
    [self addObserverBody:bodyB];
    
}

-(void)setAnchorFromBodyB
{
    if(!bodyB)
    {
        self.anchorB = CGPointZero;
        [[AppDelegate appDelegate] refreshProperty:@"anchorB"];
        return;
    }
    
    CGPoint anchorBPositionNodePos = ccpAdd(self.position, ccp(kDefaultLength,0));
    
    CGPoint worldPos = [self.parent convertToWorldSpace:anchorBPositionNodePos];
    CGPoint lAnchorb = [bodyB convertToNodeSpace:worldPos];
                               
                               
    self.anchorB = lAnchorb;
    
    [[AppDelegate appDelegate] refreshProperty:@"anchorB"];

}



-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if(object == bodyB)
    {
        return;
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}


@end
