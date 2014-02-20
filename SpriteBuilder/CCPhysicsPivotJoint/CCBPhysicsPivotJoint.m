//
//  CCBPPhysicsPivotJoint.m
//  SpriteBuilder
//
//  Created by John Twigg
//
//

#import "CCBPhysicsPivotJoint.h"
#import "AppDelegate.h"

NSString *  dependantProperties[kNumProperties] = {@"skewX", @"skewY", @"position", @"scaleX", @"scaleY", @"rotation"};


@implementation CCBPhysicsPivotJoint

- (id) init
{
    self = [super init];
    if (!self)
    {
        return NULL;
    }
    
    scaleFreeNode.scale = 1.0f;
    [self setupBody];
    
    return self;
}

-(void)setupBody
{
    
    CCSprite* joint = [CCSprite spriteWithImageNamed:@"joint-pivot.png"];
    CCSprite* jointAnchor = [CCSprite spriteWithImageNamed:@"joint-anchor.png"];
    
    [scaleFreeNode addChild:joint];
    [scaleFreeNode addChild:jointAnchor];
   // self.contentSize = joint.contentSize;
   // self.anchorPoint = ccp(0.5f,0.5f);
    
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

-(CGPoint)anchorA
{
    return anchorA;
}

-(void)setAnchorA:(CGPoint)aAnchorA
{
    anchorA = aAnchorA;
    
}


-(void)setBodyA:(CCNode *)aBodyA
{
    if(bodyA)
    {
        [self removeObserverBody:bodyA];
    }
    
    [super setBodyA:aBodyA];
    
    if(!bodyA)
    {
        self.anchorA = CGPointZero;
        [[AppDelegate appDelegate] refreshProperty:@"anchorA"];
        return;
    }

    [self setAnchorFromBodyA];
    [self addObserverBody:bodyA];
    
}

-(void)addObserverBody:(CCNode*)body
{
    for (int i = 0; i < sizeof(dependantProperties)/sizeof(dependantProperties[0]); i++)
    {
        [body addObserver:self forKeyPath:dependantProperties[i] options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial context:nil];
    }
}

-(void)removeObserverBody:(CCNode*)body
{
    for (int i = 0; i < sizeof(dependantProperties)/sizeof(dependantProperties[0]); i++) {
        [body removeObserver:self forKeyPath:dependantProperties[i]];
    }
}

-(void)setAnchorFromBodyA
{
    CGPoint worldPos = [self.parent convertToWorldSpace:self.position];
    CGPoint lAnchorA = [bodyA convertToNodeSpace:worldPos];
    self.anchorA = lAnchorA;
    
    [[AppDelegate appDelegate] refreshProperty:@"anchorA"];
   
}

-(void)setPosition:(CGPoint)position
{
    [super setPosition:position];
    
    if(!bodyA)
    {
        return;
    }
    
    [self setAnchorFromBodyA];
}


-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if(object == bodyA)
    {
        CGPoint worldPos = [bodyA convertToWorldSpace:self.anchorA];
        CGPoint localPos = [self.parent convertToNodeSpace:worldPos];
        self.position = localPos;
    }
}

-(void)dealloc
{
    if(bodyA)
    {
        [self removeObserverBody:bodyA];
    }

}


@end
