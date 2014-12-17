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
    [self.effect willChangeValueForKey:@"redOffsetWithPoint"];

    CGPoint redOffset = self.effect.redOffsetWithPoint;
    redOffset.x = x;
    self.effect.redOffsetWithPoint = redOffset;

    [self.effect didChangeValueForKey:@"redOffsetWithPoint"];
}

- (float)redOffsetX
{
    return self.effect.redOffsetWithPoint.x;
}

- (void)setRedOffsetY:(float)y
{
    [self.effect willChangeValueForKey:@"redOffsetWithPoint"];
    
    CGPoint redOffset = self.effect.redOffsetWithPoint;
    redOffset.y = y;
    self.effect.redOffsetWithPoint = redOffset;

    [self.effect didChangeValueForKey:@"redOffsetWithPoint"];
}

- (float)redOffsetY
{
    return self.effect.redOffsetWithPoint.y;
}

- (void)setGreenOffsetX:(float)x
{
    [self.effect willChangeValueForKey:@"greenOffsetWithPoint"];
    
    CGPoint greenOffset = self.effect.greenOffsetWithPoint;
    greenOffset.x = x;
    self.effect.greenOffsetWithPoint = greenOffset;
    
    [self.effect didChangeValueForKey:@"greenOffsetWithPoint"];
}

- (float)greenOffsetX
{
    return self.effect.greenOffsetWithPoint.x;
}

- (void)setGreenOffsetY:(float)y
{
    [self.effect willChangeValueForKey:@"greenOffsetWithPoint"];
    
    CGPoint greenOffset = self.effect.greenOffsetWithPoint;
    greenOffset.y = y;
    self.effect.greenOffsetWithPoint = greenOffset;
    
    [self.effect didChangeValueForKey:@"greenOffsetWithPoint"];
}

- (float)greenOffsetY
{
    return self.effect.greenOffsetWithPoint.y;
}

- (void)setBlueOffsetX:(float)x
{
    [self.effect willChangeValueForKey:@"blueOffsetWithPoint"];
    
    CGPoint blueOffset = self.effect.blueOffsetWithPoint;
    blueOffset.x = x;
    self.effect.blueOffsetWithPoint = blueOffset;
    
    [self.effect didChangeValueForKey:@"blueOffsetWithPoint"];
}

- (float)blueOffsetX
{
    return self.effect.blueOffsetWithPoint.x;
}

- (void)setBlueOffsetY:(float)y
{
    [self.effect willChangeValueForKey:@"blueOffsetWithPoint"];
    
    CGPoint blueOffset = self.effect.blueOffsetWithPoint;
    blueOffset.y = y;
    self.effect.blueOffsetWithPoint = blueOffset;
    
    [self.effect didChangeValueForKey:@"blueOffsetWithPoint"];
}

- (float)blueOffsetY
{
    return self.effect.blueOffsetWithPoint.y;
}

@end
