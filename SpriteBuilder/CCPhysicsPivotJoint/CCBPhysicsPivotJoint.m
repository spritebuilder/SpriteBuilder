//
//  CCBPPhysicsPivotJoint.m
//  SpriteBuilder
//
//  Created by John Twigg
//
//

#import "CCBPhysicsPivotJoint.h"
#import "AppDelegate.h"
#import "CCNode+NodeInfo.h"
#import "CCBPhysicsJoint+Private.h"
#import "CCButton.h"

const float kSegmentHandleDefaultRadius = 50.0f;

@interface CCSegmentHandle : CCNode
{

}

@property (nonatomic) CCDrawNode * segment;
@property (nonatomic) CCSprite * handle;
@property (nonatomic) float length;
@property (nonatomic) BOOL highlighted;

@end


@implementation CCSegmentHandle
@synthesize segment;
@synthesize handle;

-(id)init
{
    self = [super init];
    if(self)
    {
        segment = [CCDrawNode node];
        handle  = [CCSprite spriteWithImageNamed:@"joint-connection-disconnected.png"];
        [self addChild:segment];
        [self addChild:handle];
        _length = kSegmentHandleDefaultRadius;
    }
    return self;
}

-(void)setLength:(float)length
{
    self->_length = length;
}

-(void)setHighlighted:(BOOL)highlighted
{
    if(highlighted)
    {
        handle.spriteFrame = [CCSpriteFrame frameWithImageNamed:@"joint-connection-connected.png"];
    }
    else
    {
        handle.spriteFrame = [CCSpriteFrame frameWithImageNamed:@"joint-connection-disconnected.png"];
    }
}

-(void)visit:(CCRenderer *)renderer parentTransform:(const GLKMatrix4 *)parentTransform
{
    
    CGPoint nodeSpace = ccp(0.0f,self.length);
    CGPoint worldSpace = [self convertToWorldSpace:nodeSpace];
    worldSpace = ccp( floorf(worldSpace.x),
                     floorf(worldSpace.y));
    nodeSpace = [self convertToNodeSpace:worldSpace];
    
    handle.position = nodeSpace;
    [segment drawSegmentFrom:ccp(0.0f,0.0f) to:ccp(0.0f,self.length) radius:1.0f color:[CCColor redColor]];
    
    [super visit:renderer parentTransform:parentTransform];
}

@end

@interface CCBPhysicsJoint()
-(void)updateSelectionUI;
@end

@implementation CCBPhysicsPivotJoint
{
    CCSprite * joint;
    CCSprite * jointAnchor;
    
    
    CCLayoutBox * layoutControlBox;
    NSArray     * layoutButtons;
    
    CCSegmentHandle      * referenceAngleHandle;
    
    CCNode               * springNode;
    CCSegmentHandle      * springRestAngleHandle;
    
    CCNode               * limitNode;
    CCSegmentHandle      * limitMaxHandle;
    CCSegmentHandle      * limitMinHandle;
    
    CCNode               * ratchetNode;
    CCSegmentHandle      * ratchedPhaseHandle;
    CCSegmentHandle      * ratchedValueHandle;
    CCNode               * ratchedTicks;
    float                  cachedRatchedValue;
    
    
}

@synthesize anchorA;

- (id) init
{
    self = [super init];
    if (!self)
    {
        return NULL;
    }
    
    scaleFreeNode.scale = 1.0f;
    
    self.dampedSpringEnabled = NO;
    self.dampedSpringRestAngle = 0.0f;
    self.dampedSpringStiffness = 4.0f;
    self.dampedSpringDamping = 1.0f;
    
    self.limitEnabled = NO;
    self.limitMin = 0;
    self.limitMax = 90;


    self.motorEnabled = NO;
    self.motorRate = 1;


    self.ratchetEnabled = NO;
    self.ratchetValue = 30.0f;
    self.ratchetPhase = 0.0f;
    cachedRatchedValue = -1.0f;
    
    [self setupBody];
    
    return self;
}




-(void)setupBody
{
	joint = [CCSprite spriteWithImageNamed:@"joint-pivot.png"];
    jointAnchor = [CCSprite spriteWithImageNamed:@"joint-anchor.png"];
    
    [scaleFreeNode addChild:joint];
    [scaleFreeNode addChild:jointAnchor];
    
    //Layout Controls
    layoutControlBox = [CCLayoutBox node];
    NSMutableArray * buttons = [NSMutableArray array];
    for (int i =0; i < eLayoutButtonMax; i++) {
        NSString * title = i == eLayoutButtonSpring ? @"S" : (i == eLayoutButtonLimit ? @"L" : @"R");
        CCButton * button = [CCButton buttonWithTitle:title spriteFrame:[CCSpriteFrame frameWithImageNamed:@"joint-layoutbutton-bg.png"]];
        [button setBlock:^(CCButton * sender) {
            self.layoutType = [sender.userObject integerValue];
            [self refreshLayoutButtons];
        }];
            
        button.userObject = @(i);
        [buttons addObject:button ];
    }
    layoutButtons = buttons;
    layoutControlBox.position = ccp(0.0f,-40.0f);
    [scaleFreeNode addChild:layoutControlBox];
    [self refreshLayoutButtons];
    
    //Reference Angle
    referenceAngleHandle = [CCSegmentHandle node];
    [scaleFreeNode addChild:referenceAngleHandle];
    referenceAngleHandle.length = kSegmentHandleDefaultRadius * 0.7f;
    
    //Spring
    springNode = [CCNode node];
    [scaleFreeNode addChild:springNode];
    springRestAngleHandle = [CCSegmentHandle node];
    [springNode addChild:springRestAngleHandle];
    
    //Limit
    limitNode = [CCNode node];
    [scaleFreeNode addChild:limitNode];
    limitMinHandle = [CCSegmentHandle node];
    limitMinHandle.length = kSegmentHandleDefaultRadius * .7f;
    [limitNode addChild:limitMinHandle];
    
    limitMaxHandle = [CCSegmentHandle node];
    limitMaxHandle.length = kSegmentHandleDefaultRadius;
    [limitNode addChild:limitMaxHandle];
    
    //Ratched
    ratchetNode = [CCNode node];
    [scaleFreeNode addChild:ratchetNode];
    ratchedValueHandle = [CCSegmentHandle node];
    ratchedValueHandle.length = kSegmentHandleDefaultRadius;
    [ratchetNode addChild:ratchedValueHandle];
    
    ratchedPhaseHandle = [CCSegmentHandle node];
    ratchedPhaseHandle.length = kSegmentHandleDefaultRadius * .7f;
    [ratchetNode addChild:ratchedPhaseHandle];
}


-(void)visit:(CCRenderer *)renderer parentTransform:(const GLKMatrix4 *)parentTransform
{
    [self updateRenderBody];
    [super visit:renderer parentTransform:parentTransform];
}

-(float)worldRotation:(CCNode*)node
{
    float rotation = 0.0f;
    CCNode * parent = node;
    while(parent)
    {
        rotation += parent.rotation;
        parent = parent.parent;
    }

    return rotation;
}

const float kRatchedRenderRadius = 30.0f;
-(void)updateRenderRatchet
{
    if(cachedRatchedValue != self.ratchetValue)
    {
        cachedRatchedValue = self.ratchetValue;
        
        [ratchedTicks removeFromParentAndCleanup:YES];
        ratchedTicks = [CCNode node];
        float currentAngle = cachedRatchedValue;
        while (currentAngle < (360.0f - cachedRatchedValue) && currentAngle > (-360 + cachedRatchedValue))
        {
            CCDrawNode * drawNode = [CCDrawNode node];
            [drawNode drawSegmentFrom:ccp(.0f,.0f) to:ccp(0.0f, kRatchedRenderRadius) radius:1.0f color:[CCColor grayColor]];
            [ratchedTicks addChild:drawNode];
            drawNode.rotation = currentAngle;
            currentAngle += cachedRatchedValue;
        }
        
        [ratchedValueHandle addChild:ratchedTicks];
    }
}

-(void)updateRenderBody
{
    //Spring
    if(self.bodyA != nil)
    {
        float rotation = [self worldRotation:self.bodyA];
        
        springRestAngleHandle.rotation = rotation + self.referenceAngle + self.dampedSpringRestAngle + M_PI_2;
        referenceAngleHandle.rotation  = rotation + self.referenceAngle + M_PI_2;
        limitMinHandle.rotation = rotation + self.referenceAngle + self.limitMin + M_PI_2;
        limitMaxHandle.rotation = rotation + self.referenceAngle + self.limitMax + M_PI_2;
        
        if(self.layoutType == eLayoutButtonRatchet)
        {
            ratchedValueHandle.rotation = rotation + self.referenceAngle + self.ratchetValue + M_PI_2;
            ratchedPhaseHandle.rotation = rotation + self.referenceAngle + self.ratchetPhase + M_PI_2;
            [self updateRenderRatchet];
        }
        
    }
}

-(void)updateSelectionUI
{
    //If selected, display selected sprites.
    if(selectedBodyHandle & (1 << EntireJoint))
    {
        joint.spriteFrame =       [self frameWithImageNamed:@"joint-pivot-sel.png"];
        jointAnchor.spriteFrame = [self frameWithImageNamed:@"joint-anchor-sel.png"];
        
        
        //Refence angle Handle;
        referenceAngleHandle.visible = YES;
        //Spring.
        springNode.visible = self.layoutType == eLayoutButtonSpring && self.dampedSpringEnabled;
        
        //Limit
        limitNode.visible = self.layoutType == eLayoutButtonLimit && self.limitEnabled;
        
        ratchetNode.visible = self.layoutType == eLayoutButtonRatchet && self.ratchetEnabled;
        
        
        //Layout Control
        layoutControlBox.visible = YES;
    }
    //If its not selected
    else
    {
        joint.spriteFrame = [self frameWithImageNamed:@"joint-pivot.png"];
        jointAnchor.spriteFrame = [self frameWithImageNamed:@"joint-anchor.png"];
      
        springNode.visible = NO;
        referenceAngleHandle.visible = NO;
        limitNode.visible = NO;
        layoutControlBox.visible = NO;
        ratchetNode.visible = NO;
    }
    
    

    springRestAngleHandle.highlighted = selectedBodyHandle & (1 << RotarySpringRestAngleHandle);
    referenceAngleHandle.highlighted = selectedBodyHandle & (1 << ReferenceAngleHandle);
    limitMinHandle.highlighted = selectedBodyHandle & (1 << LimitMinHandle);
    limitMaxHandle.highlighted = selectedBodyHandle & (1 << LimitMaxHandle);
    ratchedValueHandle.highlighted = selectedBodyHandle& (1 << RatchedHandle);
    ratchedPhaseHandle.highlighted =selectedBodyHandle & (1 << RatchedPhaseHandle);
    
    [super updateSelectionUI];
}


- (BOOL)hitTestWithWorldPos:(CGPoint)pos
{
    pos = [scaleFreeNode convertToNodeSpace:pos];
    if(ccpLength(pos) < 17.0f)
    {
        return YES;
    }
    
    return NO;    
}


-(JointHandleType)hitTestJoint:(CGPoint)worldPos
{
    return JointHandleUnknown;
}



- (BOOL) shouldDisableProperty:(NSString*) prop
{
    if([super shouldDisableProperty:prop])
    {
        return YES;
    }
    
    if([prop isEqualToString:@"dampedspringRestAngleHandle"] ||
       [prop isEqualToString:@"dampedSpringStiffness"] ||
       [prop isEqualToString:@"dampedSpringDamping"])
    {
        return !self.dampedSpringEnabled;
    }
    
    if([prop isEqualToString:@"limitMin"] ||
       [prop isEqualToString:@"limitMax"] )
    {
        return !self.limitEnabled;
    }

    if([prop isEqualToString:@"motorRate"])
    {
        return !self.motorEnabled;
    }

    if([prop isEqualToString:@"ratchetValue"] ||
       [prop isEqualToString:@"ratchetPhase"] )
    {
        return !self.ratchetEnabled;
    }
    
    return NO;
}

-(float)rotationFromWorldPos:(CGPoint)worldPos
{
    float rotation = 0.0f;
    CCNode * parent = self.bodyA;
    while(parent)
    {
        rotation += parent.rotation;
        parent = parent.parent;
    }
    
    CGPoint newPosition = [self convertToNodeSpace:worldPos];
    CGPoint normalPos = ccpNormalize(newPosition);
    float degAngle = CC_RADIANS_TO_DEGREES(atan2f(normalPos.x, normalPos.y));
    
    degAngle -= rotation;
    return degAngle;
}

-(void)setBodyHandle:(CGPoint)worldPos bodyType:(JointHandleType)bodyType
{
    if(bodyType == BodyAnchorA)
    {
        CGPoint newPosition = [self.parent convertToNodeSpaceAR:worldPos];
        [self setPosition:newPosition];
    }
    
    if(bodyType == RotarySpringRestAngleHandle)
    {
        float degAngle = [self rotationFromWorldPos:worldPos];
        self.dampedSpringRestAngle = degAngle - self.referenceAngle;
    }
    
    if(bodyType == ReferenceAngleHandle)
    {
        float degAngle = [self rotationFromWorldPos:worldPos];
        self.referenceAngle = degAngle;
    }
    
    
    if(bodyType == LimitMaxHandle)
    {
        float degAngle = [self rotationFromWorldPos:worldPos];
        self.limitMax = degAngle - self.referenceAngle;
    }

    if(bodyType == LimitMinHandle)
    {
        float degAngle = [self rotationFromWorldPos:worldPos];
        self.limitMin = degAngle - self.referenceAngle;
    }

    if(bodyType == RatchedHandle)
    {
        float degAngle = [self rotationFromWorldPos:worldPos];
        self.ratchetValue = degAngle - self.referenceAngle;
    }

    if(bodyType == RatchedPhaseHandle)
    {
        float degAngle = [self rotationFromWorldPos:worldPos];
        self.ratchetPhase = degAngle - self.referenceAngle;
    }
}

-(void)refreshLayoutButtons
{
    [layoutControlBox removeAllChildrenWithCleanup:NO];
    for (int i = 0; i < eLayoutButtonMax; i++)
    {
        switch (i)
        {
            case eLayoutButtonLimit:
            {
                if(self.limitEnabled)
                {
                    [layoutControlBox addChild:layoutButtons[i]];
                }
            
                break;
            }
            case eLayoutButtonRatchet:
            {
                if(self.ratchetEnabled)
                {
                    [layoutControlBox addChild:layoutButtons[i]];
                }
                break;
            }

            case eLayoutButtonSpring:
            {
                if(self.dampedSpringEnabled)
                {
                    [layoutControlBox addChild:layoutButtons[i]];
                }
                break;
            }

            default:
                break;
        }
    }
    
    //If we've currently selected a button that's no longer available, select another.
    if(![layoutControlBox.children containsObject:layoutButtons[self.layoutType]] && layoutControlBox.children.count >= 1)
    {
        self.layoutType = [[layoutControlBox.children[0] userObject] integerValue];
        
    }

    
    //If there's only one item selectable, select it and clear the screen.
    if(layoutControlBox.children.count == 1)
    {
        CCButton * button = layoutControlBox.children[0];
        self.layoutType = [button.userObject integerValue];
        [layoutControlBox removeAllChildrenWithCleanup:NO];
    }
    
}

#pragma mark Properties
#pragma mark -


-(CGPoint)anchorA
{
    return anchorA;
}

-(void)setAnchorA:(CGPoint)aAnchorA
{
    anchorA = aAnchorA;
    [self setPositionFromAnchor];
    
}


-(void)setBodyA:(CCNode *)aBodyA
{
	bool bodyAChanges = false;
    if(!bodyA || !aBodyA || bodyA.UUID != aBodyA.UUID)
    {
        bodyAChanges = true;
    }
    
    [super setBodyA:aBodyA];
    
    if(!aBodyA)
    {
        self.anchorA = CGPointZero;
        [[AppDelegate appDelegate] refreshProperty:@"anchorA"];
        return;
    }
    
	if(bodyAChanges)
	{
		[self setAnchorFromBodyA];
	}
	[self setPositionFromAnchor];
}

-(void)setPositionFromAnchor
{
    if(self.bodyA == nil || self.parent == nil)
        return;
    
    CGPoint worldPos = [self.bodyA convertToWorldSpace:self.anchorA];
    CGPoint nodePos = [self.parent convertToNodeSpace:worldPos];
    self.position = nodePos;
}

-(void)setAnchorFromBodyA
{
    if(self.bodyA == nil || self.parent == nil)
        return;
    
    CGPoint worldPos = [self.parent convertToWorldSpace:self.position];
    CGPoint lAnchorA = [self.bodyA convertToNodeSpace:worldPos];
    anchorA = lAnchorA;
    
    [[AppDelegate appDelegate] refreshProperty:@"anchorA"];
    
}

-(void)setPosition:(CGPoint)position
{
    [super setPosition:position];
    
    if(!self.bodyA)
    {
        return;
    }
    
    [self setAnchorFromBodyA];
}


-(JointHandleType)hitTestJointHandle:(CGPoint)worlPos
{
    if(jointAnchor)
    {
        CGPoint pointA = [jointAnchor convertToNodeSpaceAR:worlPos];
        if(ccpLength(pointA) < 4.0f* [CCDirector sharedDirector].UIScaleFactor)
        {
            return BodyAnchorA;
        }
    }
    
    if(self.dampedSpringEnabled)
    {
        CGPoint pointHit = [springRestAngleHandle.handle convertToNodeSpaceAR:worlPos];
        if(ccpLength(pointHit) < 4.0f* [CCDirector sharedDirector].UIScaleFactor)
        {
            return RotarySpringRestAngleHandle;
        }
    }
    
    if(self.limitEnabled)
    {
        {
            CGPoint pointHit = [limitMinHandle.handle convertToNodeSpaceAR:worlPos];
            if(ccpLength(pointHit) < 4.0f* [CCDirector sharedDirector].UIScaleFactor)
            {
                return LimitMinHandle;
            }
        }
        
        {
            CGPoint pointHit = [limitMaxHandle.handle convertToNodeSpaceAR:worlPos];
            if(ccpLength(pointHit) < 4.0f* [CCDirector sharedDirector].UIScaleFactor)
            {
                return LimitMaxHandle;
            }
        }
    }
    
    if(self.ratchetEnabled)
    {
        {
            CGPoint pointHit = [ratchedValueHandle.handle convertToNodeSpaceAR:worlPos];
            if(ccpLength(pointHit) < 4.0f* [CCDirector sharedDirector].UIScaleFactor)
            {
                return RatchedHandle;
            }
        }
        {
            CGPoint pointHit = [ratchedPhaseHandle.handle convertToNodeSpaceAR:worlPos];
            if(ccpLength(pointHit) < 4.0f* [CCDirector sharedDirector].UIScaleFactor)
            {
                return RatchedPhaseHandle;
            }
        }
    }
    
    if(self.dampedSpringEnabled || self.limitEnabled  || self.ratchetEnabled)
    {
        CGPoint pointHit = [referenceAngleHandle.handle convertToNodeSpaceAR:worlPos];
        if(ccpLength(pointHit) < 4.0f* [CCDirector sharedDirector].UIScaleFactor)
        {
            return ReferenceAngleHandle;
        }
    }
    
    return [super hitTestJointHandle:worlPos];;
}

-(void)setDampedSpringRestAngle:(float)dampedSpringRestAngle
{
    _dampedSpringRestAngle = dampedSpringRestAngle;
    [[AppDelegate appDelegate]refreshProperty:@"dampedSpringRestAngle"];
}


-(void)setReferenceAngle:(float)referenceAngle
{
    _referenceAngle = referenceAngle;
    [[AppDelegate appDelegate]refreshProperty:@"referenceAngle"];
}

-(void)setLimitMax:(float)limitMax
{
    _limitMax = limitMax;
    [[AppDelegate appDelegate]refreshProperty:@"limitMax"];
}

-(void)setLimitMin:(float)limitMin
{
    _limitMin = limitMin;
    [[AppDelegate appDelegate]refreshProperty:@"limitMin"];
}

-(void)setRatchetPhase:(float)ratchetPhase
{
    _ratchetPhase = ratchetPhase;
    [[AppDelegate appDelegate]refreshProperty:@"ratchetPhase"];
}

-(void)setRatchetValue:(float)ratchetValue
{
    if(ratchetValue < 2.0f && ratchetValue > -2.0f)
    {
        if(ratchetValue > 0.0f)
            ratchetValue = 2.0f;
        
        if(ratchetValue < 0.0f)
            ratchetValue = -2.0f;
        
    }
    
    _ratchetValue = ratchetValue;
    [[AppDelegate appDelegate]refreshProperty:@"ratchetValue"];
}

-(void)setDampedSpringEnabled:(BOOL)dampedSpringEnabled
{
    _dampedSpringEnabled = dampedSpringEnabled;
    if(_dampedSpringDamping)
    {
        self.layoutType = eLayoutButtonSpring;
    }
    
    [self refreshLayoutButtons];
}

-(void)setLimitEnabled:(BOOL)limitEnabled
{
    _limitEnabled = limitEnabled;
    
    if(_limitEnabled)
    {
        self.layoutType = eLayoutButtonLimit;
    }
    
    [self refreshLayoutButtons];
}

-(void)setRatchetEnabled:(BOOL)ratchetEnabled
{
    _ratchetEnabled = ratchetEnabled;
    
    if(_ratchetEnabled)
    {
        self.layoutType = eLayoutButtonRatchet;
    }
    
    [self refreshLayoutButtons];
}

#pragma mark -
#pragma mark KVO
+(BOOL)nodeHasParent:(CCNode*)node parent:(CCNode*)parent
{
    while(node)
    {
        if(node == parent)
            return YES;
        
        node = node.parent;
    }
    
    return NO;
}



-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([CCBPhysicsPivotJoint nodeHasParent:self.bodyA parent:object])
    {
        CGPoint worldPos = [self.bodyA convertToWorldSpace:self.anchorA];
        CGPoint localPos = [self.parent convertToNodeSpace:worldPos];
        self.position = localPos;
    }
}

-(void)onEnter
{
	[super onEnter];
	[self setPositionFromAnchor];
}


-(void)dealloc
{
    self.bodyA = nil;

}


@end
