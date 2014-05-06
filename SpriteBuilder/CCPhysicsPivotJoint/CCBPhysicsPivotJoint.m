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



@interface CCBPhysicsJoint()
-(void)updateSelectionUI;
@end

@implementation CCBPhysicsPivotJoint
{
    CCSprite * joint;
    CCSprite * jointAnchor;
    
    CCSprite * restAngleHandle;
    
    

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
    
    [self setupBody];
    
    return self;
}

const float kRestAngleRadius = 50.0f;

-(void)setupBody
{
	joint = [CCSprite spriteWithImageNamed:@"joint-pivot.png"];
    jointAnchor = [CCSprite spriteWithImageNamed:@"joint-anchor.png"];
    
    [scaleFreeNode addChild:joint];
    [scaleFreeNode addChild:jointAnchor];
    
    restAngleHandle = [CCSprite spriteWithImageNamed:@"joint-connection-disconnected.png"];

    
}


-(void)visit:(CCRenderer *)renderer parentTransform:(const GLKMatrix4 *)parentTransform
{
    [self updateRenderBody];
    [super visit:renderer parentTransform:parentTransform];
}

-(void)updateRenderBody
{
    if(self.bodyA != nil)
    {
        float rotation = 0.0f;
        CCNode * parent = self.bodyA;
        while(parent)
        {
            rotation += parent.rotation;
            parent = parent.parent;
        }
        
        rotation += _dampedSpringRestAngle + M_PI_2;
        

        CGPoint bodyARelative = ccp(sinf(CC_DEGREES_TO_RADIANS(rotation)),
                                    cosf(CC_DEGREES_TO_RADIANS(rotation)));
        
        CGPoint nodeSapce = ccpMult(bodyARelative,kRestAngleRadius);
        restAngleHandle.position = nodeSapce;
    }

}

-(void)updateSelectionUI
{
    //If selected, display selected sprites.
    if(selectedBodyHandle & (1 << EntireJoint))
    {
        joint.spriteFrame =       [self frameWithImageNamed:@"joint-pivot-sel.png"];
        jointAnchor.spriteFrame = [self frameWithImageNamed:@"joint-anchor-sel.png"];
        
        if(self.dampedSpringEnabled && restAngleHandle.parent == nil)
        {
            [scaleFreeNode addChild:restAngleHandle];
        }
        else if(!self.dampedSpringEnabled && restAngleHandle.parent != nil)
        {
            [restAngleHandle removeFromParentAndCleanup:NO];
        }

    }
    //If its not selected na
    else
    {
        joint.spriteFrame = [self frameWithImageNamed:@"joint-pivot.png"];
        jointAnchor.spriteFrame = [self frameWithImageNamed:@"joint-anchor.png"];
        
        if(restAngleHandle.parent != nil)
            [restAngleHandle removeFromParentAndCleanup:NO];
    }
    
    if(selectedBodyHandle & (1 << RestAngleHandle))
    {
        restAngleHandle.spriteFrame = [self frameWithImageNamed:@"joint-connection-connected.png"];
    }
    else
    {
        restAngleHandle.spriteFrame = [self frameWithImageNamed:@"joint-connection-disconnected.png"];
    }

    
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
        CGPoint pointHit = [restAngleHandle convertToNodeSpaceAR:worlPos];
        if(ccpLength(pointHit) < 4.0f* [CCDirector sharedDirector].UIScaleFactor)
        {
            return RestAngleHandle;
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
    
    if([prop isEqualToString:@"dampedSpringRestAngle"] || [prop isEqualToString:@"dampedSpringStiffness"] || [prop isEqualToString:@"dampedSpringDamping"])
    {
        return !self.dampedSpringEnabled;
    }
    
    return NO;
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
        
        self.dampedSpringRestAngle = degAngle;
    }
}

-(void)setDampedSpringRestAngle:(float)dampedSpringRestAngle
{
    _dampedSpringRestAngle = dampedSpringRestAngle;
    [[AppDelegate appDelegate]refreshProperty:@"dampedSpringRestAngle"];
    
    
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
