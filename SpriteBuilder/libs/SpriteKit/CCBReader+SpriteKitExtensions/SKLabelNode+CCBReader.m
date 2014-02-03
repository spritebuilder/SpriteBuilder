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

@end
