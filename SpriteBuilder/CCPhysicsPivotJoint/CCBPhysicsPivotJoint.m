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
        for (int i = 0; i < sizeof(dependantProperties)/sizeof(dependantProperties[0]); i++)
        {
            [bodyA removeObserver:self forKeyPath:dependantProperties[i]];
        }
    }
    
    [super setBodyA:aBodyA];
    
    if(!bodyA)
    {
        self.anchorA = CGPointZero;
        [[AppDelegate appDelegate] refreshProperty:@"anchorA"];
        return;
    }

    CGPoint worldPos = [self.parent convertToWorldSpace:self.position];
    CGPoint lAnchorA = [bodyA convertToNodeSpace:worldPos];
    self.anchorA = lAnchorA;
    [[AppDelegate appDelegate] refreshProperty:@"anchorA"];
    
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
    self.anchorA = lAnchorPos;
    
    [[AppDelegate appDelegate] refreshProperty:@"anchorPos"];
}


-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    CGPoint worldPos = [bodyA convertToWorldSpace:self.anchorA];
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
