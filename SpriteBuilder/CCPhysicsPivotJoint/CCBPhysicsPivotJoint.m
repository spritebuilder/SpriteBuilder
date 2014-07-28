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
#import "NSArray+Query.h"
#import "CCProgressNode.h"

const float kSegmentHandleDefaultRadius = 17.0f;

@interface CCSegmentHandle : CCNode
{

}

@property (nonatomic) CCSprite * handle;


@end


@implementation CCSegmentHandle
@synthesize handle;

-(id)init
{
    self = [super init];
    if(self)
    {
        handle  = [CCSprite spriteWithImageNamed:@"joint-pivot-handle-ref.png"];
        handle.anchorPoint = ccp(0.5f,0.0f);
        [self addChild:handle];
    }
    return self;
}

-(BOOL)hitTestWithWorldPos:(CGPoint)worlPos
{
    CGPoint pointHit = [self.handle convertToNodeSpaceAR:worlPos];
    pointHit.y = pointHit.y - self.handle.contentSizeInPoints.height + 6.0f * [CCDirector sharedDirector].UIScaleFactor;

    if(ccpLength(pointHit) < 4.0f )
    {
        return YES;;
    }

    return NO;
}

-(void)visit:(CCRenderer *)renderer parentTransform:(const GLKMatrix4 *)parentTransform
{
    
    CGPoint nodeSpace = ccp(0.0f,kSegmentHandleDefaultRadius * [CCDirector sharedDirector].UIScaleFactor);
    CGPoint worldSpace = [self convertToWorldSpace:nodeSpace];
    worldSpace = ccp( floorf(worldSpace.x),
                     floorf(worldSpace.y));
    nodeSpace = [self convertToNodeSpace:worldSpace];
    handle.position = nodeSpace;
    
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
    CCNode      * layoutBox;
    CCSprite    * layoutBackground;
    
    CCSegmentHandle      * referenceAngleHandle;
    
    CCNode               * springNode;
    CCSegmentHandle      * springRestAngleHandle;
    
    CCNode               * limitNode;
    CCSegmentHandle      * limitMaxHandle;
    CCSegmentHandle      * limitMinHandle;
    CCProgressNode       * limitSubtendingAngle;
    BOOL                   limitSubtendingAngleValid;
    
    CCNode               * ratchetNode;
    CCSegmentHandle      * ratchedPhaseHandle;
    CCSegmentHandle      * ratchedValueHandle;
    CCNode               * ratchedTicks;
    float                  cachedRatchedValue;
    
    CCSprite             * motorNode;
    
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
    limitSubtendingAngleValid = NO;

    self.motorEnabled = NO;
    self.motorRate = 1;
    self.motorMaxForce = 100.0f;
    self.motorMaxForceEnabled = NO;

    self.ratchetEnabled = NO;
    self.ratchetValue = 30.0f;
    self.ratchetPhase = 0.0f;
    
    cachedRatchedValue = -1.0f;
    _layoutType = eLayoutButtonNone;
    
    [self setupBody];
    
    return self;
}




-(void)setupBody
{
	joint = [CCSprite spriteWithImageNamed:@"joint-pivot.png"];
    jointAnchor = [CCSprite spriteWithImageNamed:@"joint-anchor.png"];
    
    [scaleFreeNode addChild:joint];
    [scaleFreeNode addChild:jointAnchor];
 
    [self createLayoutButtons];
   
    //Reference Angle
    referenceAngleHandle = [CCSegmentHandle node];
    [scaleFreeNode addChild:referenceAngleHandle];
    referenceAngleHandle.handle.spriteFrame = [CCSpriteFrame frameWithImageNamed:@"joint-pivot-handle-ref.png"];
    
    //Spring
    springNode = [CCNode node];
    [scaleFreeNode addChild:springNode];
    springRestAngleHandle = [CCSegmentHandle node];
    [springNode addChild:springRestAngleHandle];
    springRestAngleHandle.handle.spriteFrame = [CCSpriteFrame frameWithImageNamed:@"joint-pivot-handle-max.png"];
    
    //Limit
    limitNode = [CCNode node];
    [scaleFreeNode addChild:limitNode];
    
    CCSprite * progressSprite = [CCSprite spriteWithImageNamed:@"joint-pivot-range.png"];
    limitSubtendingAngle = [CCProgressNode progressWithSprite:progressSprite];
    limitSubtendingAngle.type = CCProgressNodeTypeRadial;
    [limitNode addChild:limitSubtendingAngle];
    
    limitMaxHandle = [CCSegmentHandle node];
    limitMaxHandle.handle.spriteFrame = [CCSpriteFrame frameWithImageNamed:@"joint-pivot-handle-max.png"];
    [limitNode addChild:limitMaxHandle];
    
    limitMinHandle = [CCSegmentHandle node];
    limitMinHandle.handle.spriteFrame = [CCSpriteFrame frameWithImageNamed:@"joint-pivot-handle-min.png"];
    [limitNode addChild:limitMinHandle];
    
    //Ratched
    ratchetNode = [CCNode node];
    [scaleFreeNode addChild:ratchetNode];
    ratchedValueHandle = [CCSegmentHandle node];
    [ratchetNode addChild:ratchedValueHandle];
    ratchedValueHandle.handle.spriteFrame =[CCSpriteFrame frameWithImageNamed:@"joint-pivot-handle-ratchet.png"];

    ratchedPhaseHandle = [CCSegmentHandle node];
    [ratchetNode addChild:ratchedPhaseHandle];
    ratchedPhaseHandle.handle.spriteFrame =[CCSpriteFrame frameWithImageNamed:@"joint-pivot-handle-min.png"];

    //Motor
    motorNode = [CCSprite spriteWithImageNamed:@"joint-pivot-motor.png"];
    [scaleFreeNode addChild:motorNode];
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
        while (currentAngle < (360.0f - cachedRatchedValue) &&
               currentAngle > (-360 - cachedRatchedValue) &&
               (cachedRatchedValue > 0.0f ?
               (currentAngle + cachedRatchedValue * self.ratchetPhase / 360.0f + cachedRatchedValue) <= 360.0f :
               (currentAngle - cachedRatchedValue * self.ratchetPhase / 360.0f + cachedRatchedValue) >= -360.0f))
        {
            CCSprite * sprite = [CCSprite spriteWithImageNamed:@"joint-pivot-handle-ratchetmark.png"];
            sprite.anchorPoint = ccp(0.5f,0.0f);
            [ratchedTicks addChild:sprite];
            sprite.rotation = currentAngle;
            sprite.position = ccpRotateByAngle(ccp(0.0f, kSegmentHandleDefaultRadius),ccp(0.0f,0.0f),CC_DEGREES_TO_RADIANS(-currentAngle));
            currentAngle += cachedRatchedValue;
        }
        
        ratchedTicks.rotation = ratchedValueHandle.rotation;
        [ratchetNode addChild:ratchedTicks z:-1];
    }
}

-(void)updateLimit
{
    if(limitSubtendingAngleValid)
        return;
    
    limitSubtendingAngleValid = YES;
    limitSubtendingAngle.percentage = 100.0f * (self.limitMax - self.limitMin) / 360.0f;

}

-(void)updateRenderBody
{
    //Spring
    if(self.bodyA != nil)
    {
        float rotation = [self worldRotation:self.bodyA];
        
        springRestAngleHandle.rotation  = rotation + self.referenceAngle + self.dampedSpringRestAngle + M_PI_2;
        referenceAngleHandle.rotation   = rotation + self.referenceAngle + M_PI_2;
        limitMinHandle.rotation         = rotation + self.referenceAngle + self.limitMin + M_PI_2;
        limitMaxHandle.rotation         = rotation + self.referenceAngle + self.limitMax + M_PI_2;
        limitSubtendingAngle.rotation   = limitMinHandle.rotation;
        
        if(self.layoutType == eLayoutButtonRatchet)
        {
            ratchedValueHandle.rotation = rotation + self.referenceAngle + self.ratchetValue + (self.ratchetValue) * self.ratchetPhase/360.0f + M_PI_2;
            ratchedPhaseHandle.rotation = rotation + self.referenceAngle + (self.ratchetValue) * self.ratchetPhase/360.0f + M_PI_2;
            [self updateRenderRatchet];
        }
        
        if(self.layoutType == eLayoutButtonLimit)
        {
            [self updateLimit];
        }
    }
}

-(void)updateSelectionUI
{
    BOOL bodyAssigned = self.bodyA != nil && self.bodyB != nil;
    
    //If selected, display selected sprites.
    if(selectedBodyHandle & (1 << EntireJoint))
    {
        joint.spriteFrame =       [self frameWithImageNamed:@"joint-pivot-sel.png"];
        jointAnchor.spriteFrame = [self frameWithImageNamed:@"joint-anchor-sel.png"];
        
        
        //Refence angle Handle;
        referenceAngleHandle.visible = bodyAssigned && (self.dampedSpringEnabled || self.limitEnabled || self.ratchetEnabled);
        
        //Spring.
        springNode.visible = bodyAssigned &&self.layoutType == eLayoutButtonSpring && self.dampedSpringEnabled;
        
        //Limit
        limitNode.visible = bodyAssigned &&self.layoutType == eLayoutButtonLimit && self.limitEnabled;
        
        ratchetNode.visible = bodyAssigned && self.layoutType == eLayoutButtonRatchet && self.ratchetEnabled;
        
        
        //Layout Control
        layoutBox.visible = bodyAssigned;
    }
    //If its not selected
    else
    {
        joint.spriteFrame = [self frameWithImageNamed:@"joint-pivot.png"];
        jointAnchor.spriteFrame = [self frameWithImageNamed:@"joint-anchor.png"];
      
        springNode.visible = NO;
        referenceAngleHandle.visible = NO;
        limitNode.visible = NO;
        layoutBox.visible = NO;
        ratchetNode.visible = NO;

        
    }
    
    //Motor nodes. Its always visible.
    motorNode.visible = bodyAssigned && self.motorEnabled;
    motorNode.scaleX = self.motorRate > 0.0f ? -1.0f : 1.0f;

    
    //Make them equivalent.
    layoutBackground.visible = layoutBox.visible && layoutControlBox.children.count >= 1;
    
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
    
    if([prop isEqualToString:@"dampedSpringRestAngle"] ||
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
        float degAngle = [self rotationFromWorldPos: worldPos] - self.referenceAngle;
        
        if(degAngle < 0.0f)
        {
            float halfMin = self.limitMin / 2.0f;
        
            if(degAngle <  halfMin)
                degAngle = 360 + degAngle;
            else
                degAngle = 0.0f;
        }
        
        //Within limits, then set.
        if(degAngle < (360 + self.limitMin))
        {
            self.limitMax = degAngle ;
        }
        else
        {
            self.limitMax = (360 + self.limitMin);
        }
    }

    if(bodyType == LimitMinHandle)
    {
        float degAngle = [self rotationFromWorldPos: worldPos] - self.referenceAngle;
        if(degAngle > 0.0f )
        {
            //Figure out it we should Zero snap or limitMax snap.
            float halfMax = self.limitMax/2.0f;
            if(degAngle < halfMax)
            {
                degAngle = 0.0f;
            }
            else
            {
                degAngle = -360 + degAngle;
            }
        }
       
        //Within limits, then set.
        if(self.limitMax - 360  <= degAngle)
        {
            self.limitMin = degAngle ;
        }
        else
        {
            self.limitMin = (self.limitMax - 360);
        }
        
    }

    if(bodyType == RatchedHandle)
    {
        float degAngle = [self rotationFromWorldPos:worldPos];
        float currentAngle = degAngle - self.referenceAngle;
        float oldAngle = self.ratchetValue + self.ratchetValue * self.ratchetPhase / 360.0f;
        float delta = (currentAngle - oldAngle) / (1 + self.ratchetPhase / 360.0f);
        self.ratchetValue = self.ratchetValue  + delta;
    }

    if(bodyType == RatchedPhaseHandle)
    {
        float degAngle = [self rotationFromWorldPos:worldPos];
        self.ratchetPhase = 360.0f * degAngle / self.ratchetValue;
    }
}

-(void)createLayoutButtons
{
    
    //Layout Controls
    layoutBox = [CCNode node];
    layoutControlBox = [CCLayoutBox node];
    layoutControlBox.spacing = 2.0f * [CCDirector sharedDirector].UIScaleFactor;
    NSMutableArray * buttons = [NSMutableArray array];
    for (int i =0; i < eLayoutButtonMax; i++) {
        NSString * title = i == eLayoutButtonSpring ? @"s" : (i == eLayoutButtonLimit ? @"l" : @"r");

        CCSpriteFrame * offSpriteFrame = [CCSpriteFrame frameWithImageNamed:[NSString stringWithFormat:@"joint-pivot-mode-%@-off.png",title]];
        CCSpriteFrame * onSpriteFrame = [CCSpriteFrame frameWithImageNamed: [NSString stringWithFormat:@"joint-pivot-mode-%@-on.png",title]];
        
        CCButton * button = [CCButton buttonWithTitle:@"" spriteFrame:offSpriteFrame highlightedSpriteFrame:onSpriteFrame disabledSpriteFrame:offSpriteFrame];
        
        [button setBlock:^(CCButton * sender) {
            self.layoutType = [sender.userObject integerValue];
        }];
        
        button.userObject = @(i);
        [buttons addObject:button ];
    }
    layoutButtons = buttons;
    
    layoutBackground = [CCSprite spriteWithImageNamed:@"joint-pivot-mode-bg.png"];
    layoutBackground.anchorPoint = ccp(0.0f,0.0f);
    [layoutBox addChild:layoutBackground z:-1];
    [layoutBox addChild:layoutControlBox];;
    layoutBox.position = ccp(0.0f,-70.0f * [CCDirector sharedDirector].UIScaleFactor);
    
    [scaleFreeNode addChild:layoutBox];
    
}
-(void)refreshLayoutButtons
{
    [layoutControlBox removeAllChildrenWithCleanup:NO];
    
    if(_layoutType == eLayoutButtonNone)
        return;
    
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
        _layoutType = [[layoutControlBox.children[0] userObject] integerValue];
        
    }
    
    //If there's only one item selectable, select it and clear the screen.
    if(layoutControlBox.children.count == 1)
    {
        CCButton * button = layoutControlBox.children[0];
        _layoutType = [button.userObject integerValue];
        [layoutControlBox removeAllChildrenWithCleanup:NO];
    }
    
    
    //Make sure all the other buttons are off off.
    [layoutButtons forEach:^(CCButton * button, int idx) {
        button.selected = ([button.userObject integerValue] == self.layoutType);
    }];
    
    if(layoutControlBox.children.count ==0)
        return;
    
    layoutBackground.scaleX = (float)layoutControlBox.children.count / (float)layoutButtons.count;
    
    layoutBackground.position = ccpMult(ccp(-2.f * layoutBackground.scaleX,-2.0f),[CCDirector sharedDirector].UIScaleFactor);
    
    
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
        if([springRestAngleHandle hitTestWithWorldPos:worlPos])
            return RotarySpringRestAngleHandle;
        
    }
    
    if(self.limitEnabled)
    {
        if([limitMinHandle hitTestWithWorldPos:worlPos])
            return LimitMinHandle;
        
        
        if([limitMaxHandle hitTestWithWorldPos:worlPos])
            return LimitMaxHandle;
        
    }
    
    if(self.ratchetEnabled)
    {
        if([ratchedValueHandle hitTestWithWorldPos:worlPos])
            return RatchedHandle;
        
        if([ratchedPhaseHandle hitTestWithWorldPos:worlPos])
            return RatchedPhaseHandle;
        
    }
    
    if(self.dampedSpringEnabled || self.limitEnabled  || self.ratchetEnabled)
    {
        if([referenceAngleHandle hitTestWithWorldPos:worlPos])
            return ReferenceAngleHandle;
        
    }
    
    return [super hitTestJointHandle:worlPos];;
}

-(void)setDampedSpringRestAngle:(float)dampedSpringRestAngle
{
    _dampedSpringRestAngle = dampedSpringRestAngle;
    [[AppDelegate appDelegate] refreshProperty:@"dampedSpringRestAngle"];
}

-(void)setDampedSpringStiffness:(float)dampedSpringStiffness
{
	if(dampedSpringStiffness < 0)
	{
		[[AppDelegate appDelegate] modalDialogTitle:@"Stiffness Restrictions" message:@"The spring stiffness must be greater than Zero"];
		[[AppDelegate appDelegate] performSelector:@selector(refreshProperty:) withObject:@"dampedSpringStiffness" afterDelay:0];
		return;
	}
	_dampedSpringStiffness = dampedSpringStiffness;
}

-(void)setReferenceAngle:(float)referenceAngle
{
    _referenceAngle = referenceAngle;
    cachedRatchedValue = -1.0f;
    [[AppDelegate appDelegate]refreshProperty:@"referenceAngle"];
}

-(void)setLimitMax:(float)limitMax
{
    if(limitMax >= 0 && (limitMax <= (360 + _limitMin)))
    {
        _limitMax = limitMax;
    }
    
    limitSubtendingAngleValid = NO;
    [[AppDelegate appDelegate]refreshProperty:@"limitMax"];
}

-(void)setLimitMin:(float)limitMin
{
    if(limitMin <= 0.0f && ((360 + limitMin) >= _limitMax))
    {
        _limitMin = limitMin;
    }
    
    limitSubtendingAngleValid = NO;
    [[AppDelegate appDelegate]refreshProperty:@"limitMin"];
}

-(void)setRatchetPhase:(float)ratchetPhase
{
    _ratchetPhase = ratchetPhase;
    _ratchetPhase = fmaxf(0.0f,_ratchetPhase);
    _ratchetPhase = fminf(360.0f,_ratchetPhase);
    
    cachedRatchedValue = -1.0f;
    
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
    cachedRatchedValue = -1.0f;
    [[AppDelegate appDelegate]refreshProperty:@"ratchetValue"];
}

-(void)setDampedSpringEnabled:(BOOL)dampedSpringEnabled
{
    _dampedSpringEnabled = dampedSpringEnabled;
    if(_dampedSpringDamping && _layoutType != eLayoutButtonNone)
    {
        self.layoutType = eLayoutButtonSpring;
    }
    
    [self refreshLayoutButtons];
}

-(void)setLimitEnabled:(BOOL)limitEnabled
{
    _limitEnabled = limitEnabled;
    
    if(_limitEnabled && _layoutType != eLayoutButtonNone)
    {
        self.layoutType = eLayoutButtonLimit;
    }
    
    [self refreshLayoutButtons];
}

-(void)setRatchetEnabled:(BOOL)ratchetEnabled
{
    _ratchetEnabled = ratchetEnabled;
    
    if(_ratchetEnabled && _layoutType != eLayoutButtonNone)
    {
        self.layoutType = eLayoutButtonRatchet;
    }
    [self refreshLayoutButtons];
}


-(void)setMotorMaxForceEnabled:(BOOL)motorMaxForceEnabled
{
	if(_motorMaxForceEnabled != motorMaxForceEnabled)
	{
		if(motorMaxForceEnabled && isinf(self.motorMaxForce))
			self.motorMaxForce = 100.0f;
		
	}
	
	_motorMaxForceEnabled = motorMaxForceEnabled;
}

-(void)setLayoutType:(eLayoutButtonType)layoutType
{
    _layoutType = layoutType;
    [self refreshLayoutButtons];
}

-(void)onEnter
{
	[super onEnter];

	[self setPositionFromAnchor];
    if(_layoutType == eLayoutButtonNone)
    {
        self.layoutType = eLayoutButtonSpring;
    }
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




-(void)dealloc
{
    self.bodyA = nil;

}


@end
