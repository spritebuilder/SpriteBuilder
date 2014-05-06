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
    
    
    CCLayoutBox * layoutControls;
    
    CCSegmentHandle      * referenceAngleHandle;
    
    CCNode               * springNode;
    CCSegmentHandle      * springRestAngleHandle;
    

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

    
    [self setupBody];
    
    return self;
}



typedef enum
{
    eLayoutButtonSpring,
    eLayoutButtonLimit,
    eLayoutButtonRatchet,
    eLayoutButtonMax
    
} eLayoutButtonType;

-(void)setupBody
{
	joint = [CCSprite spriteWithImageNamed:@"joint-pivot.png"];
    jointAnchor = [CCSprite spriteWithImageNamed:@"joint-anchor.png"];
    
    [scaleFreeNode addChild:joint];
    [scaleFreeNode addChild:jointAnchor];
    
    //Layout Controls
    layoutControls = [CCLayoutBox node];
    for (int i =0; i < eLayoutButtonMax; i++) {
        NSString * title = i == eLayoutButtonSpring ? @"S" : (i == eLayoutButtonLimit ? @"L" : @"R");
        CCButton * button = [CCButton buttonWithTitle:title spriteFrame:[CCSpriteFrame frameWithImageNamed:@"joint-layoutbutton-bg.png"]];
        [layoutControls addChild:button];
    }
    layoutControls.position = ccp(0.0f,-40.0f);
    
    [scaleFreeNode addChild:layoutControls];
    
    referenceAngleHandle = [CCSegmentHandle node];
    referenceAngleHandle.length = kSegmentHandleDefaultRadius * 0.7f;
    [scaleFreeNode addChild:referenceAngleHandle];
    //Spring
    springNode = [CCNode node];
    [scaleFreeNode addChild:springNode];
    
    springRestAngleHandle = [CCSegmentHandle node];
    [springNode addChild:springRestAngleHandle];
    
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

-(void)updateRenderBody
{
    //Spring
    if(self.bodyA != nil)
    {
        float rotation = [self worldRotation:self.bodyA];
        
        springRestAngleHandle.rotation = rotation + self.referenceAngle + self.dampedSpringRestAngle + M_PI_2;
        referenceAngleHandle.rotation  = rotation + self.referenceAngle + M_PI_2;
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
        if(referenceAngleHandle.parent == nil)
        {
            [scaleFreeNode addChild:referenceAngleHandle];
        }
        
        //Spring.
        if(self.dampedSpringEnabled && springNode.parent == nil)
        {
            [scaleFreeNode addChild:springNode];
        }
        else if(!self.dampedSpringEnabled && springNode.parent != nil)
        {
            [springNode removeFromParentAndCleanup:NO];
        }
        
    }
    //If its not selected
    else
    {
        joint.spriteFrame = [self frameWithImageNamed:@"joint-pivot.png"];
        jointAnchor.spriteFrame = [self frameWithImageNamed:@"joint-anchor.png"];
        
        if(springNode.parent != nil)
        {
            [springNode removeFromParentAndCleanup:NO];
        }
        
        if(referenceAngleHandle.parent != nil)
        {
            [referenceAngleHandle removeFromParentAndCleanup:NO];
        }
    }
    
    

    springRestAngleHandle.highlighted = selectedBodyHandle & (1 << RestAngleHandle);
    referenceAngleHandle.highlighted = selectedBodyHandle & (1 << ReferenceAngleHandle);
    

    
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
            return RestAngleHandle;
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
    
    if(bodyType == RestAngleHandle)
    {
        float degAngle = [self rotationFromWorldPos:worldPos];
        self.dampedSpringRestAngle = degAngle - self.referenceAngle;
    }
    
    if(bodyType == ReferenceAngleHandle)
    {
        float degAngle = [self rotationFromWorldPos:worldPos];
        self.referenceAngle = degAngle;
    }
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
