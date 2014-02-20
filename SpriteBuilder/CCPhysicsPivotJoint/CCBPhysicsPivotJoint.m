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
