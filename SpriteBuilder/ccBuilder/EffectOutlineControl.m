//
//  EffectOutlineControl.m
//  SpriteBuilder
//
//  Created by Oleg Osin on 12/13/14.
//
//

#import "EffectOutlineControl.h"

@interface EffectOutlineControl ()

@end

@implementation EffectOutlineControl

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void) setColor:(NSColor *)color
{
    CGFloat r, g, b, a;
    
    [color getRed:&r green:&g blue:&b alpha:&a];
    
    CCColor* colorValue = [CCColor colorWithRed:r green:g blue:b alpha:a];
    self.effect.outlineColor = colorValue;
}

- (NSColor*) color
{
    CCColor* colorValue = self.effect.outlineColor;
    NSColor * calibratedColor = colorValue.NSColor;
    
    return calibratedColor;
}

@end
