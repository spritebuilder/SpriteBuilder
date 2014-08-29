//
//  SBMenuItem.m
//  SpriteBuilder
//
//  Created by John Twigg on 8/5/14.
//
//

#import "SBMenuItem.h"

@implementation SBMenuItem

-(NSString*)title
{
#ifdef SPRITEBUILDER_PRO
	NSString * localTitle = [super title];
	localTitle = [localTitle stringByReplacingOccurrencesOfString:@"SpriteBuilder" withString:@"SpriteBuilder Pro"];
	return localTitle;
#else 
	return [super title];
#endif
							 
}
@end
