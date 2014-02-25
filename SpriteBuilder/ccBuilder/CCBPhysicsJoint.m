//
//  CCBPhysicsJoint.m
//  SpriteBuilder
//
//  Created by John Twigg on 2/19/14.
//
//

#import "CCBPhysicsJoint.h"
#import "CCScaleFreeNode.h"
#import "CCNode+NodeInfo.h"
#import "CCBGlobals.h"
#import "SceneGraph.h"

static const float kOutletOffset = 20.0f;

NSString *  dependantProperties[kNumProperties] = {@"skewX", @"skewY", @"position", @"scaleX", @"scaleY", @"rotation"};

@implementation CCBPhysicsJoint
{

}
@dynamic bodyA;
@dynamic bodyB;

@synthesize isSelected;
- (id) init
{
    self = [super init];
    if (!self)
    {
        return nil;
    }
    
    scaleFreeNode = [CCScaleFreeNode node];
    [self addChild:scaleFreeNode];
    
    bodyAOutlet = [CCSprite spriteWithImageNamed:@"joint-outlet-unset.png"];
    bodyAOutlet.position = ccp(-kOutletOffset,-kOutletOffset);
    [scaleFreeNode addChild:bodyAOutlet];
    
    bodyBOutlet = [CCSprite spriteWithImageNamed:@"joint-outlet-unset.png"];
    bodyBOutlet.position = ccp(kOutletOffset,-kOutletOffset);
    [scaleFreeNode addChild:bodyBOutlet];
    
    return self;
}

-(void)setBodyA:(CCNode *)aBodyA
{
    if(bodyA && bodyA != aBodyA)
    {
        [self removeObserverBody:bodyA];
    }
    
    bodyA = aBodyA;
    bodyA_UUID = bodyA.UUID;
    
    [self addObserverBody:bodyA];
    [self refreshOutletStatus];
}

-(void)setBodyB:(CCNode *)aBodyB
{
    if(bodyB && bodyB != aBodyB)
    {
        [self removeObserverBody:bodyB];
    }
        
    bodyB = aBodyB;
    bodyB_UUID = bodyB.UUID;
    [self addObserverBody:bodyB];
    [self refreshOutletStatus];
}

-(void)fixupReferences
{
    self.bodyA = self.bodyA;
    self.bodyB = self.bodyB;
        
    if(self.bodyA.nodePhysicsBody == nil)
    {
        self.bodyA = nil;
    }
    
    if(self.bodyB.nodePhysicsBody == nil)
    {
        self.bodyB = nil;
    }
}


-(void)addObserverBody:(CCNode*)body
{
    for (int i = 0; i < sizeof(dependantProperties)/sizeof(dependantProperties[0]); i++)
    {
        [body addObserver:self forKeyPath:dependantProperties[i] options:NSKeyValueObservingOptionNew context:nil];
    }
    
}

-(void)removeObserverBody:(CCNode*)body
{
    for (int i = 0; i < sizeof(dependantProperties)/sizeof(dependantProperties[0]); i++) {
        [body removeObserver:self forKeyPath:dependantProperties[i]];
    }
}

-(CCNode*)bodyA
{
    CCNode * foundNode = [self findUUID:bodyA_UUID];
    //NSAssert(foundNode != nil, @"Did not find nod UUID:%i", (int)bodyA_UUID);
    return foundNode;
}

-(CCNode*)bodyB
{
    CCNode * foundNode = [self findUUID:bodyB_UUID];
    //NSAssert(foundNode != nil, @"Did not find nod UUID:%i", (int)bodyA_UUID);
    return foundNode;
}

typedef CCNode* (^FindUUIDBlock)(CCNode * node, NSUInteger uuid);

-(CCNode*)findUUID:(NSUInteger)uuid
{
    if(uuid == 0)
        return nil;
        
    
    
    __block FindUUIDBlock findUUIDT;
    //Recursive.
    findUUIDT = ^CCNode*(CCNode * node, NSUInteger uuid)
    {
        if(node.UUID == uuid)
            return node;
        
        for (CCNode * child in node.children) {
            CCNode * foundNode = findUUIDT(child,uuid);
            
            if(foundNode)
                return foundNode;
            
        }
        return nil;
    };
    
    CCNode * foundNode = findUUIDT(sceneGraph.rootNode,uuid);
    
    return foundNode;
}

-(void)visit
{
    [self updateSelectionUI];
    [super visit];
}

-(void)updateSelectionUI
{
    
    if(self.isSelected)
    {
        bodyAOutlet.visible = self.bodyA ? NO : YES;
        bodyBOutlet.visible = self.bodyB ? NO : YES;

    }
    else
    {
        bodyAOutlet.visible = NO;
        bodyBOutlet.visible = NO;
    }
    
    isSelected = NO;
}

-(int)hitTestOutlet:(CGPoint)point
{

    CGPoint pointA = [bodyAOutlet convertToNodeSpaceAR:point];
    
    if(ccpLength(pointA) < 5.0f)
    {
        return 0;
    }
    
    
    CGPoint pointB = [bodyBOutlet convertToNodeSpaceAR:point];
    if(ccpLength(pointB) < 5.0f)
    {
        return 1;
    }
    
    return -1;
}

-(void)refreshOutletStatus
{
    CCSpriteFrame * spriteFrameUnset = [CCSpriteFrame frameWithImageNamed:@"joint-outlet-unset.png"];
    CCSpriteFrame * spriteFrameSet = [CCSpriteFrame frameWithImageNamed:@"joint-outlet-set.png"];
    
    bodyAOutlet.spriteFrame = bodyA ? spriteFrameSet : spriteFrameUnset;
    bodyBOutlet.spriteFrame = bodyB ? spriteFrameSet : spriteFrameUnset;
    
}

-(CGPoint)outletWorldPos:(int)idx
{
    if(idx == 0)
    {
        return [bodyAOutlet convertToWorldSpaceAR:CGPointZero];
    }
    else
    {
        return [bodyBOutlet convertToWorldSpaceAR:CGPointZero];
    }
}




-(void)setOutletStatus:(int)idx value:(BOOL)value
{
    CCSprite * bodyOutlet = idx == 0 ? bodyAOutlet : bodyBOutlet;
    if(value)
    {
        bodyOutlet.spriteFrame = [CCSpriteFrame frameWithImageNamed:@"joint-outlet-set.png"];
    }
    else
    {
        bodyOutlet.spriteFrame = [CCSpriteFrame frameWithImageNamed:@"joint-outlet-unset.png"];
    }
}

-(void)onEnter
{
    [super onEnter];
    sceneGraph = [SceneGraph instance];
}


-(void)dealloc
{
    self.bodyA = nil;
    self.bodyB = nil;
}

@end