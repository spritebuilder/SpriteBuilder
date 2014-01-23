//
//  CCLabelTTF+SKLabelNode.m
//  SpriteBuilder
//
//  Created by Steffen Itterheim on 23/01/14.
//
//

#import "CCLabelTTF+SKLabelNode.h"

@implementation CCLabelTTF (SKLabelNode)

-(void) setText:(NSString *)text
{
	self.string = text;
}
-(NSString*) text
{
	return self.string;
}

@end
