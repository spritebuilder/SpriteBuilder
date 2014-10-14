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

static const float kOutletHorizontalOffset = 8.0f;

NSString *  dependantProperties[kNumProperties] = {@"skewX", @"skewY", @"position", @"scaleX", @"scaleY", @"rotation", @"anchorPoint"};



@implementation CCBPhysicsJoint
{


}
@dynamic bodyA;
@dynamic bodyB;

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
    
	bodyOutletRoot = [CCNode node];
	bodyOutletRoot.position = ccp([self outletHorizontalOffset],-[self outletVerticalOffset]);
	bodyOutletRoot.positionType = CCPositionTypeUIPoints;
	
	CCSprite * outletBG = [CCSprite spriteWithImageNamed:@"joint-connection-bg.png"];
	outletBG.positionType = CCPositionTypeUIPoints;
	[bodyOutletRoot addChild:outletBG];
	
    bodyAOutlet = [CCSprite spriteWithImageNamed:@"joint-connection-disconnected.png"];
    bodyAOutlet.positionType = CCPositionTypeUIPoints;
    bodyAOutlet.position = ccp(-kOutletHorizontalOffset, 0);
    [bodyOutletRoot addChild:bodyAOutlet];
    
    bodyBOutlet = [CCSprite spriteWithImageNamed:@"joint-connection-disconnected.png"];
    bodyBOutlet.position = ccp(kOutletHorizontalOffset, 0);
    bodyBOutlet.positionType = CCPositionTypeUIPoints;
	[bodyOutletRoot addChild:bodyBOutlet];
   
	[scaleFreeNode addChild:bodyOutletRoot];
	
    self.breakingForceEnabled = NO;
    self.maxForceEnabled = NO;
    self.breakingForce = 100.0f;
    self.collideBodies = NO;
    self.maxForce = 100.0f;
    
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


-(float)outletHorizontalOffset
{
    return 0.0f;
}

-(float)outletVerticalOffset
{
    return 30.0f;
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

-(BOOL)isDraggable
{
	return YES;
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
		bodyOutletRoot.visible = (self.bodyA && self.bodyB) ? NO : YES;
    }
    else
    {
		bodyOutletRoot.visible = NO;
    }
    
    //Outlet A
    if(selectedBodyHandle & (1<<BodyOutletA) || self.bodyA)
    {
        bodyAOutlet.spriteFrame = [self frameWithImageNamed:@"joint-connection-connected.png"];
    }
    else
    {
        bodyAOutlet.spriteFrame = [self frameWithImageNamed:@"joint-connection-disconnected.png"];
    }
    [self removeJointHandleSelected:BodyOutletA];
    
    //Outlet B
    if(selectedBodyHandle & (1<<BodyOutletB) || self.bodyB)
    {
        bodyBOutlet.spriteFrame = [self frameWithImageNamed:@"joint-connection-connected.png"];
    }
    else
    {
        bodyBOutlet.spriteFrame = [self frameWithImageNamed:@"joint-connection-disconnected.png"];
    }
	
    [self removeJointHandleSelected:BodyOutletB];
    [self removeJointHandleSelected:EntireJoint];
}


#pragma mark -


-(JointHandleType)hitTestJointHandle:(CGPoint)worldPos
{

    CGPoint pointA = [bodyAOutlet convertToNodeSpaceAR:worldPos];
    if(bodyA == nil &&  ccpLength(pointA) < 8.0f * [CCDirector sharedDirector].UIScaleFactor)
    {
        return BodyOutletA;
    }
    
    
    CGPoint pointB = [bodyBOutlet convertToNodeSpaceAR:worldPos];
    if(bodyB == nil && ccpLength(pointB) < 8.0f * [CCDirector sharedDirector].UIScaleFactor)
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

-(void)clearJointHandleSelected
{
	selectedBodyHandle = 0x0;
}

-(void)setBodyHandle:(CGPoint)worldPos bodyType:(JointHandleType)bodyType
{
    //Do nothing.
}

-(void)refreshOutletStatus
{
    CCSpriteFrame * spriteFrameUnset = [self frameWithImageNamed:@"joint-connection-disconnected.png"];
    CCSpriteFrame * spriteFrameSet   = [self frameWithImageNamed:@"joint-connection-connected.png"];
    
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

-(void)setBreakingForceEnabled:(BOOL)breakingForceEnabled
{
	if(_breakingForceEnabled != breakingForceEnabled)
	{
		if(breakingForceEnabled && isinf(self.breakingForce))
			self.breakingForce = 100.0f;
	}
	
	_breakingForceEnabled = breakingForceEnabled;
}

-(void)setMaxForceEnabled:(BOOL)maxForceEnabled
{
	if(_maxForceEnabled != maxForceEnabled)
	{
		if(maxForceEnabled && isinf(self.maxForce))
			self.maxForce = 100.0f;
		
	}
	
	_maxForceEnabled = maxForceEnabled;
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