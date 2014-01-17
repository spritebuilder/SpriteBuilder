//
//  SKLabelNode+CCBReader.m
//  SpriteKitReader-Experimental
//
//  Created by Steffen Itterheim on 17/01/14.
//  Copyright (c) 2014 Steffen Itterheim. All rights reserved.
//

#import "SKLabelNode+CCBReader.h"

@implementation SKLabelNode (CCBReader)

-(void) setString:(NSString *)string
{
	self.text = string;
}
-(NSString*) string
{
	return self.text;
}

-(void) setOutlineColor:(CCColor*)outlineColor
{
	self.fontColor = [SKColor colorWithRed:outlineColor.red
									 green:outlineColor.green
									  blue:outlineColor.blue
									 alpha:outlineColor.alpha];
}
-(CCColor*) outlineColor
{
	CGFloat r, g, b, a;
	[self.color getRed:&r green:&g blue:&b alpha:&a];
	return [CCColor colorWithRed:r green:g blue:b alpha:a];
}

@end
