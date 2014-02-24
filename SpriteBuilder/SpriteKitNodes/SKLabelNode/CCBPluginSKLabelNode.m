//
//  CCBPNode.m
//  SpriteBuilder
//
//  Created by Viktor on 12/17/13.
//
//

#import "CCBPluginSKLabelNode.h"

@implementation CCBPluginSKLabelNode

-(void) setText:(NSString *)text
{
	self.string = text;
}
-(NSString*) text
{
	return self.string;
}

@end
