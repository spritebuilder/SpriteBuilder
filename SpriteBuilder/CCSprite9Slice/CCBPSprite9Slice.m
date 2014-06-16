//
//  CCBPSprite9Slice.m
//  SpriteBuilder
//
//  Created by Viktor on 12/17/13.
//
//

#import "CCBPSprite9Slice.h"
#import "AppDelegate.h"

@implementation CCBPSprite9Slice


- (void)setMargin:(float)margin
{
    margin = clampf(margin, 0, 0.5);
	[super setMargin:margin];
}

// ---------------------------------------------------------------------

- (void)setMarginLeft:(float)marginLeft
{
    marginLeft = clampf(marginLeft, 0, 1);
	
	if(self.marginRight + marginLeft >= 1)
	{
		[[AppDelegate appDelegate] modalDialogTitle:@"Margin Restrictions" message:@"The left & right margins should add up to less than 1"];
		[[AppDelegate appDelegate] performSelector:@selector(refreshProperty:) withObject:@"marginLeft" afterDelay:0];
		return;
	}
	[super setMarginLeft:marginLeft];
}

- (void)setMarginRight:(float)marginRight
{
    marginRight = clampf(marginRight, 0, 1);
	if(self.marginLeft + marginRight >= 1)
	{
		[[AppDelegate appDelegate] modalDialogTitle:@"Margin Restrictions" message:@"The left & right margins should add up to less than 1"];
		[[AppDelegate appDelegate] performSelector:@selector(refreshProperty:) withObject:@"marginRight" afterDelay:0];
		
		return;
	}
	
	[super setMarginRight:marginRight];
}

- (void)setMarginTop:(float)marginTop
{
    marginTop = clampf(marginTop, 0, 1);
	if(self.marginBottom + marginTop >= 1)
	{
		[[AppDelegate appDelegate] modalDialogTitle:@"Margin Restrictions" message:@"The top & bottom margins should add up to less than 1"];
		[[AppDelegate appDelegate] performSelector:@selector(refreshProperty:) withObject:@"marginTop" afterDelay:0];
		return;
	}
	
	[super setMarginTop:marginTop];
   
}

- (void)setMarginBottom:(float)marginBottom
{
    marginBottom = clampf(marginBottom, 0, 1);
	if(self.marginTop + marginBottom >= 1)
	{
		[[AppDelegate appDelegate] modalDialogTitle:@"Margin Restrictions" message:@"The top & bottom margins should add up to less than 1"];
		[[AppDelegate appDelegate] performSelector:@selector(refreshProperty:) withObject:@"marginBottom" afterDelay:0];
		return;
	}
	
	[super setMarginBottom:marginBottom];
}

@end
