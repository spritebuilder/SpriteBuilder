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

-(void) setColor:(CCColor*)color
{
	self.color = color.skColor;
}
-(CCColor*) color
{
	return [CCColor colorWithSKColor:self.color];
}

-(void) setCcb_fontColor:(CCColor*)fontColor
{
	self.fontColor = fontColor.skColor;
}
-(CCColor*) ccb_fontColor
{
	return [CCColor colorWithSKColor:self.fontColor];
}

@end
