//
//  EffectLightingControl.m
//  SpriteBuilder
//
//  Created by Thayer J Andrews on 11/18/14.
//
//

#import "EffectLightingControl.h"

@interface EffectLightingControl ()

@end

@implementation EffectLightingControl

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}

-(void)setColor:(NSColor *)color
{
    [self.effect willChangeValueForKey:@"specularColor"];
    
    NSColor *rgbColor = [color colorUsingColorSpace:[NSColorSpace deviceRGBColorSpace]];
    self.effect.specularColor = [CCColor colorWithRed:rgbColor.redComponent green:rgbColor.greenComponent blue:rgbColor.blueComponent alpha:rgbColor.alphaComponent];

    [self.effect didChangeValueForKey:@"specularColor"];
}

- (NSColor*)color
{
    return self.effect.specularColor.NSColor;
}

@end
