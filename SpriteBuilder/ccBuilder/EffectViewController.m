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
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.

    }
    return self;
}

-(void)setHighlight:(BOOL)lHighlight
{
	self->highlight = lHighlight;

	CALayer *viewLayer = [CALayer layer];
	
	if(self.highlight)
		[viewLayer setBackgroundColor:CGColorCreateGenericRGB(0.0f, 0.0f, 1.0f, 0.5f)];
	else
		[viewLayer setBackgroundColor:CGColorCreateGenericRGB(0.0f, 0.0f, 0.0f, 0.0f)];
	
	[self.view setWantsLayer:YES];
	[self.view setLayer:viewLayer];
}

@end
