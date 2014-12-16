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
    [self.effect willChangeValueForKey:@"outlineColor"];
    
    NSColor *rgbColor = [color colorUsingColorSpace:[NSColorSpace deviceRGBColorSpace]];
    
    self.effect.outlineColor = [CCColor colorWithRed:rgbColor.redComponent green:rgbColor.greenComponent blue:rgbColor.blueComponent alpha:rgbColor.alphaComponent];
}

- (NSColor*) color
{
    CCColor* colorValue = self.effect.outlineColor;
    NSColor * calibratedColor = colorValue.NSColor;
    
    return calibratedColor;
}

@end
