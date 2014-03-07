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
@synthesize breakingForceEnabled;
@synthesize maxForceEnabled;


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
    bodyAOutlet.position = ccpMult(ccp(-kOutletOffset,-kOutletOffset),1/[CCDirector sharedDirector].contentScaleFactor);
    [scaleFreeNode addChild:bodyAOutlet];
    
    bodyBOutlet = [CCSprite spriteWithImageNamed:@"joint-outlet-unset.png"];
    bodyBOutlet.position = ccpMult(ccp(kOutletOffset,-kOutletOffset),1/[CCDirector sharedDirector].contentScaleFactor);
    [scaleFreeNode addChild:bodyBOutlet];
    
    self.breakingForceEnabled = YES;
    self.maxForceEnabled = YES;
    self.breakingForce = INFINITY;
    self.collideBodies = YES;
    self.maxForce = INFINITY;
    
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

-(BOOL)maxForceEnabled
{
    return maxForceEnabled;
}



-(void)setMaxForceEnabled:(BOOL)lMaxForceEnabled
{
    maxForceEnabled = lMaxForceEnabled;
    if(!maxForceEnabled)
    {
        [self willChangeValueForKey:@"maxForce"];
        _maxForce = INFINITY;
        [self didChangeValueForKey:@"maxForce"];
    }
    
}

-(BOOL)breakingForceEnabled
{
    return breakingForceEnabled;
}

-(void)setBreakingForceEnabled:(BOOL)lBreakingForceEnabled
{
    breakingForceEnabled = lBreakingForceEnabled;
    if(!breakingForceEnabled)
    {
        [self willChangeValueForKey:@"breakingForce"];
        _breakingForce = INFINITY;
        [self didChangeValueForKey:@"breakingForce"];
    }
}

-(CCNode*)bodyA
{
    CCNode * foundNode = [SceneGraph findUUID:bodyA_UUID rootNode:sceneGraph.rootNode];
    //NSAssert(foundNode != nil, @"Did not find nod UUID:%i", (int)bodyA_UUID);
    return foundNode;
}

-(CCNode*)bodyB
{
    CCNode * foundNode = [SceneGraph findUUID:bodyB_UUID rootNode:sceneGraph.rootNode];
    //NSAssert(foundNode != nil, @"Did not find nod UUID:%i", (int)bodyA_UUID);
    return foundNode;
}


-(void)visit
{
    [self updateSelectionUI];
    [super visit];
}

-(void)updateSelectionUI
{
    
    if(selectedBodyHandle & (1<<EntireJoint))
    {
        bodyAOutlet.visible = self.bodyA ? NO : YES;
        bodyBOutlet.visible = self.bodyB ? NO : YES;
    }
    else
    {
        bodyAOutlet.visible = NO;
        bodyBOutlet.visible = NO;
    }
    

    [self removeJointHandleSelected:EntireJoint];
}


#pragma mark -


-(JointHandleType)hitTestJointHandle:(CGPoint)worldPos
{

    CGPoint pointA = [bodyAOutlet convertToNodeSpaceAR:worldPos];
    
    pointA = ccpAdd(pointA, ccp(0,5.0f));
    if(ccpLength(pointA) < 10.0f)
    {
        return BodyOutletA;
    }
    
    
    CGPoint pointB = [bodyBOutlet convertToNodeSpaceAR:worldPos];
    pointB = ccpAdd(pointB, ccp(0,5.0f));
    if(ccpLength(pointB) < 10.0f)
    {
        return BodyOutletB;
    }

    
    return JointHandleUnknown;
}

#pragma mark -

-(void)setJointHandleSelected:(JointHandleType)handleType;
{
    selectedBodyHandle |= (1<<handleType);
}

-(void)removeJointHandleSelected:(JointHandleType)handleType
{
    selectedBodyHandle = ~(1<<handleType) & selectedBodyHandle;
}

-(void)setBodyHandle:(CGPoint)worldPos bodyType:(JointHandleType)bodyType
{
    //Do nothing.
}

-(void)refreshOutletStatus
{
    CCSpriteFrame * spriteFrameUnset = [CCSpriteFrame frameWithImageNamed:@"joint-outlet-unset.png"];
    CCSpriteFrame * spriteFrameSet = [CCSpriteFrame frameWithImageNamed:@"joint-outlet-set.png"];
    
    bodyAOutlet.spriteFrame = bodyA ? spriteFrameSet : spriteFrameUnset;
    bodyBOutlet.spriteFrame = bodyB ? spriteFrameSet : spriteFrameUnset;
    
}

-(CGPoint)outletWorldPos:(JointHandleType)idx
{
    if(idx == BodyOutletA)
    {
        return [bodyAOutlet convertToWorldSpaceAR:CGPointZero];
    }
    else
    {
        return [bodyBOutlet convertToWorldSpaceAR:CGPointZero];
    }
}




-(void)setOutletStatus:(JointHandleType)idx value:(BOOL)value
{
    CCSprite * bodyOutlet = idx == BodyOutletA ? bodyAOutlet : bodyBOutlet;
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


#pragma PasteBoard


- (id) pasteboardPropertyListForType:(NSString *)pbType
{
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    
    if ([pbType isEqualToString:@"com.cocosbuilder.jointBody"])
    {
        [dict setObject:@(self.UUID) forKey:@"jointUUID"];
        return dict;
    }
    return NULL;
}

- (NSArray *)writableTypesForPasteboard:(NSPasteboard *)pasteboard
{
    NSMutableArray* pbTypes = [NSMutableArray arrayWithObject: @"com.cocosbuilder.jointBody"];
    return pbTypes;
}


+(NSString *)convertBodyTypeToString:(JointHandleType)index
{
    switch (index) {
        case BodyOutletA:
        case BodyAnchorA:
            return @"bodyA";
        case BodyAnchorB:
        case BodyOutletB:
        default:
            return @"bodyB";
    }
}


@end