//
//  CCBPPhysicsPivotJoint.m
//  SpriteBuilder
//
//  Created by John Twigg
//
//

#import "CCBPhysicsPivotJoint.h"
#import "AppDelegate.h"

NSString *  dependantProperties[] = {@"skewX", @"skewY", @"position", @"scaleX", @"scaleY", @"rotation"};

@interface  ScaleFreeNode : CCNode
{
    float hiddenScale;
}

@end

@implementation ScaleFreeNode

-(void)visit
{
    CCNode * parent = self.parent;
    float scale = 1.0f;
    while (parent) {
        scale *= parent.scale;
        parent = parent.parent;
    }
    
    
    [self setScaleX:(hiddenScale * 1.0f/scale)];
    [self setScaleY:(hiddenScale * 1.0f/scale)];
    
    [super visit];
 
}

-(void)setScale:(float)scale
{
    [super setScale:scale];
    hiddenScale = scale;
}




@end


static const float kOutletOffset = 20.0f;


@implementation CCBPhysicsJoint

- (id) init
{
    self = [super init];
    if (!self)
    {
        return nil;
    }
    
    scaleFreeNode = [ScaleFreeNode node];
    [self addChild:scaleFreeNode];

    bodyAOutlet = [CCSprite spriteWithImageNamed:@"joint-outlet-unset.png"];
    bodyAOutlet.position = ccp(-kOutletOffset,-kOutletOffset);
    [scaleFreeNode addChild:bodyAOutlet];
    
    bodyBOutlet = [CCSprite spriteWithImageNamed:@"joint-outlet-unset.png"];
    bodyBOutlet.position = ccp(kOutletOffset,-kOutletOffset);
    [scaleFreeNode addChild:bodyBOutlet];
    
    return self;
}

-(int)hitTestOutlet:(CGPoint)point
{
    point = [self convertToNodeSpace:point];
    
    if(ccpDistance(point, bodyAOutlet.position) < 3.0f * 3.0f)
    {
        return 0;
    }
    
    if(ccpDistanceSQ(point, bodyBOutlet.position) < 3.0f * 3.0f)
    {
        return 1;
    }
    
    return -1;
}

-(void)setBodyA:(CCNode *)aBodyA
{
    bodyA = aBodyA;
    [self resetOutletStatus];
}


-(void)setBodyB:(CCNode *)aBodyB
{
    bodyB = aBodyB;
    [self resetOutletStatus];
}

-(CCNode*)bodyA
{
    return bodyA;
}

-(CCNode*)bodyB
{
    return bodyB;
}

-(void)resetOutletStatus
{
    bodyAOutlet.visible = self.bodyA ? NO : YES;
    bodyBOutlet.visible = self.bodyB ? NO : YES;
    
    bodyAOutlet.spriteFrame = [CCSpriteFrame frameWithImageNamed:@"joint-outlet-unset.png"];
    bodyBOutlet.spriteFrame = [CCSpriteFrame frameWithImageNamed:@"joint-outlet-unset.png"];

}

-(CGPoint)outletPos:(int)idx
{
    return idx ==0 ? bodyAOutlet.position : bodyBOutlet.position;    
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

@end

@implementation CCBPhysicsPivotJoint

- (id) init
{
    self = [super init];
    if (!self)
    {
        return NULL;
    }
    
    scaleFreeNode.scale = 1.0f;
    
    CCSprite* joint = [CCSprite spriteWithImageNamed:@"joint-pivot.png"];
    CCSprite* jointAnchor = [CCSprite spriteWithImageNamed:@"joint-anchor.png"];
    
    [scaleFreeNode addChild:joint];
    [scaleFreeNode addChild:jointAnchor];
    
    
    return self;
}


-(void)visit
{
    [super visit];
}

-(CGPoint)anchorPos
{
    return anchorPos;
}

-(void)setAnchorPos:(CGPoint)aAnchorPos
{
    anchorPos = aAnchorPos;
    
}

-(void)setBodyA:(CCNode *)aBodyA
{
    if(bodyA)
    {
        for (int i = 0; i < sizeof(dependantProperties)/sizeof(dependantProperties[0]); i++)
        {
            [bodyA removeObserver:self forKeyPath:dependantProperties[i]];
        }
    }
    
    [super setBodyA:aBodyA];
    
    if(!bodyA)
    {
        self.anchorPos = CGPointZero;
        [[AppDelegate appDelegate] refreshProperty:@"anchorPos"];
        return;
    }

    CGPoint worldPos = [self.parent convertToWorldSpace:self.position];
    CGPoint lAnchorPos = [bodyA convertToNodeSpace:worldPos];
    self.anchorPos = lAnchorPos;
    [[AppDelegate appDelegate] refreshProperty:@"anchorPos"];
    
    for (int i = 0; i < sizeof(dependantProperties)/sizeof(dependantProperties[0]); i++)
    {
        [bodyA addObserver:self forKeyPath:dependantProperties[i] options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial context:nil];
        
    }
    

}

-(void)setPosition:(CGPoint)position
{
    [super setPosition:position];
    
    if(!bodyA)
    {
        return;
    }
    
    CGPoint worldPos = [self.parent convertToWorldSpace:self.position];
    CGPoint lAnchorPos = [bodyA convertToNodeSpace:worldPos];
    self.anchorPos = lAnchorPos;
    
    [[AppDelegate appDelegate] refreshProperty:@"anchorPos"];
}


-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    CGPoint worldPos = [bodyA convertToWorldSpace:self.anchorPos];
    CGPoint localPos = [self.parent convertToNodeSpace:worldPos];
    self.position = localPos;
}

-(void)dealloc
{
    if(bodyA)
    {
        for (int i = 0; i < sizeof(dependantProperties)/sizeof(dependantProperties[0]); i++) {
            [bodyA removeObserver:self forKeyPath:dependantProperties[i]];
        }
        
    }

}


@end
