//
//  SKSpriteNode+CCBReader.m
//  SpriteKitReader-Experimental
//
//  Created by Steffen Itterheim on 16/01/14.
//  Copyright (c) 2014 Steffen Itterheim. All rights reserved.
//

#import "SKSpriteNode+CCBReader.h"
#import "CCBSpriteKitCompatibility.h"

@implementation SKSpriteNode (CCBReader)

-(void) setCcb_color:(CCColor *)ccb_color
{
	self.color = [SKColor colorWithRed:ccb_color.red
								 green:ccb_color.green
								  blue:ccb_color.blue
								 alpha:ccb_color.alpha];
}
-(CCColor*) ccb_color
{
	CGFloat r, g, b, a;
	[self.color getRed:&r green:&g blue:&b alpha:&a];
	return [CCColor colorWithRed:r green:g blue:b alpha:a];
}

@end
