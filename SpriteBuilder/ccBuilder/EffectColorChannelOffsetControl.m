//
//  EffectColorChannelOffsetControl.m
//  SpriteBuilder
//
//  Created by Thayer on 12/10/14.
//
//

#import "EffectColorChannelOffsetControl.h"

@interface EffectColorChannelOffsetControl ()

@end

@implementation EffectColorChannelOffsetControl

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)setRedOffsetX:(float)x
{
    [self.effect willChangeValueForKey:@"redOffset"];

    self.effect.redOffset = CGPointMake(x, self.effect.redOffset.y);

    [self.effect didChangeValueForKey:@"redOffset"];
}

- (float)redOffsetX
{
    return self.effect.redOffset.x;
}

- (void)setRedOffsetY:(float)y
{
    [self.effect willChangeValueForKey:@"redOffset"];

    self.effect.redOffset = CGPointMake(self.effect.redOffset.x, y);

    [self.effect didChangeValueForKey:@"redOffset"];
}

- (float)redOffsetY
{
    return self.effect.redOffset.y;
}

- (void)setGreenOffsetX:(float)x
{
    [self.effect willChangeValueForKey:@"greenOffset"];

    self.effect.greenOffset = CGPointMake(x, self.effect.greenOffset.y);
    
    [self.effect didChangeValueForKey:@"greenOffset"];
}

- (float)greenOffsetX
{
    return self.effect.greenOffset.x;
}

- (void)setGreenOffsetY:(float)y
{
    [self.effect willChangeValueForKey:@"greenOffset"];
    
    self.effect.greenOffset = CGPointMake(self.effect.greenOffset.x, y);
    
    [self.effect didChangeValueForKey:@"greenOffset"];
}

- (float)greenOffsetY
{
    return self.effect.greenOffset.y;
}

- (void)setBlueOffsetX:(float)x
{
    [self.effect willChangeValueForKey:@"blueOffset"];

    self.effect.blueOffset = CGPointMake(x, self.effect.blueOffset.y);
    
    [self.effect didChangeValueForKey:@"blueOffset"];
}

- (float)blueOffsetX
{
    return self.effect.blueOffset.x;
}

- (void)setBlueOffsetY:(float)y
{
    [self.effect willChangeValueForKey:@"blueOffset"];
    
    self.effect.blueOffset = CGPointMake(self.effect.blueOffset.x, y);
    
    [self.effect didChangeValueForKey:@"blueOffset"];
}

- (float)blueOffsetY
{
    return self.effect.blueOffset.y;
}

@end
