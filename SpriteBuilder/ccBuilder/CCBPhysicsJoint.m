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
#import "SequencerHandler.h"
#import "SequencerSequence.h"
#import "AppDelegate.h"

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
    
    spriteFrameCache = [NSMutableDictionary dictionary];
    
    scaleFreeNode = [CCScaleFreeNode node];
    [self addChild:scaleFreeNode];
    
    bodyAOutlet = [CCSprite spriteWithImageNamed:@"joint-outlet-unset.png"];
    bodyAOutlet.positionType = CCPositionTypeUIPoints;
    bodyAOutlet.position = ccp(-kOutletOffset + [self outletLateralOffset], -kOutletOffset);
    [scaleFreeNode addChild:bodyAOutlet];
    
    bodyBOutlet = [CCSprite spriteWithImageNamed:@"joint-outlet-unset.png"];
    bodyBOutlet.position = ccp(kOutletOffset + [self outletLateralOffset], -kOutletOffset);
    bodyBOutlet.positionType = CCPositionTypeUIPoints;
    [scaleFreeNode addChild:bodyBOutlet];
    
    self.breakingForceEnabled = NO;
    self.maxForceEnabled = NO;
    self.breakingForce = INFINITY;
    self.collideBodies = NO;
    self.maxForce = INFINITY;
    
    return self;
}

-(CCSpriteFrame*)frameWithImageNamed:(NSString*)name;
{
    CCSpriteFrame * spriteFrame = spriteFrameCache[name];
  
    if(!spriteFrame)
    {
        [spriteFrameCache setObject:[CCSpriteFrame frameWithImageNamed:name] forKey:name];
        spriteFrame = spriteFrameCache[name];
    }
   
    return spriteFrame;
    
}


-(float)outletLateralOffset
{
    return 0.0f;
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

- (BOOL) locked
{
    if([super locked])
        return YES;
    
    return self.parent.locked;
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
    CCNode * node = body;
    
    while (node && node != [SceneGraph instance].rootNode)
    {
        for (int i = 0; i < sizeof(dependantProperties)/sizeof(dependantProperties[0]); i++)
        {
            [node addObserver:self forKeyPath:dependantProperties[i] options:NSKeyValueObservingOptionNew context:nil];
        }
        node = node.parent;
    }
}

-(void)removeObserverBody:(CCNode*)body
{
    CCNode * node = body;
    
    while (node && node != [SceneGraph instance].rootNode)
    {
        
        for (int i = 0; i < sizeof(dependantProperties)/sizeof(dependantProperties[0]); i++) {
            [node removeObserver:self forKeyPath:dependantProperties[i]];
        }
        
        node = node.parent;
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
    CCNode * foundNode = [SceneGraph findUUID:bodyA_UUID node:sceneGraph.rootNode];
    //NSAssert(foundNode != nil, @"Did not find nod UUID:%i", (int)bodyA_UUID);
    return foundNode;
}

-(CCNode*)bodyB
{
    CCNode * foundNode = [SceneGraph findUUID:bodyB_UUID node:sceneGraph.rootNode];
    //NSAssert(foundNode != nil, @"Did not find nod UUID:%i", (int)bodyA_UUID);
    return foundNode;
}


-(void)visit:(CCRenderer *)renderer parentTransform:(const GLKMatrix4 *)parentTransform
{
    [self updateSelectionUI];
    [super visit:renderer parentTransform:parentTransform];
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
    

    //Outlet A
    if(selectedBodyHandle & (1<<BodyOutletA))
    {
        bodyAOutlet.spriteFrame = [self frameWithImageNamed:@"joint-outlet-set.png"];
    }
    else
    {
        bodyAOutlet.spriteFrame = [self frameWithImageNamed:@"joint-outlet-unset.png"];
    }
    [self removeJointHandleSelected:BodyOutletA];
    
    //Outlet B
    if(selectedBodyHandle & (1<<BodyOutletB))
    {
        bodyBOutlet.spriteFrame = [self frameWithImageNamed:@"joint-outlet-set.png"];
    }
    else
    {
        bodyBOutlet.spriteFrame = [self frameWithImageNamed:@"joint-outlet-unset.png"];
    }
    [self removeJointHandleSelected:BodyOutletB];

    [self removeJointHandleSelected:EntireJoint];
}


#pragma mark -


-(JointHandleType)hitTestJointHandle:(CGPoint)worldPos
{

    CGPoint pointA = [bodyAOutlet convertToNodeSpaceAR:worldPos];
    
    pointA = ccpAdd(pointA, ccp(0, 3.0f * [CCDirector sharedDirector].UIScaleFactor));
    if(ccpLength(pointA) < 8.0f * [CCDirector sharedDirector].UIScaleFactor)
    {
        return BodyOutletA;
    }
    
    
    CGPoint pointB = [bodyBOutlet convertToNodeSpaceAR:worldPos];
    pointB = ccpAdd(pointB, ccp(0, 3.0f * [CCDirector sharedDirector].UIScaleFactor));
    if(ccpLength(pointB) < 8.0f * [CCDirector sharedDirector].UIScaleFactor)
    {
        return BodyOutletB;
    }

    
    return [self hitTestWithWorldPos:worldPos] ? EntireJoint : JointHandleUnknown;
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
    CCSpriteFrame * spriteFrameUnset = [self frameWithImageNamed:@"joint-outlet-unset.png"];
    CCSpriteFrame * spriteFrameSet   = [self frameWithImageNamed:@"joint-outlet-set.png"];
    
    bodyAOutlet.spriteFrame = bodyA ? spriteFrameSet : spriteFrameUnset;
    bodyBOutlet.spriteFrame = bodyB ? spriteFrameSet : spriteFrameUnset;
    
    [self removeJointHandleSelected:BodyOutletA];
    [self removeJointHandleSelected:BodyOutletB];
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

- (BOOL) hidden
{
    if([SequencerHandler sharedHandler].currentSequence.timelinePosition != 0.0f || ![SequencerHandler sharedHandler].currentSequence.autoPlay)
    {
        return YES;
    }
    
    if([AppDelegate appDelegate].playingBack)
    {
        return YES;
    }
    
    return [super hidden];
}


@end