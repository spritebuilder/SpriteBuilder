//
//  EffectViewController.m
//  SpriteBuilder
//
//  Created by John Twigg on 6/24/14.
//
//

#import "EffectViewController.h"

@interface EffectViewController ()

@end

@implementation EffectViewController
@synthesize highlight;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil effect:(id<EffectProtocol>)effect
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        self.effect = effect;
        [self.view setWantsLayer:YES];        
    }
    return self;
}

-(void)setHighlight:(BOOL)lHighlight
{
	self->highlight = lHighlight;

	CALayer *viewLayer = [CALayer layer];
	
	if(self.highlight)
		[viewLayer setBackgroundColor:CGColorCreateGenericRGB(0.8f, 0.87f, 0.92f, 1.0f)];
	else
		[viewLayer setBackgroundColor:CGColorCreateGenericRGB(0.0f, 0.0f, 0.0f, 0.0f)];
    
	[self.view setLayer:viewLayer];
}

@end
