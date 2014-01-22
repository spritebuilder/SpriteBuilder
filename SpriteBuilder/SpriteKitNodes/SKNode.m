//
//  SKNode.m
//  SpriteBuilder
//
//  Created by Steffen Itterheim on 22/01/14.
//
//

#import "SKNode.h"

@implementation SKNode

-(void) setValue:(id)value forUndefinedKey:(NSString *)key
{
	NSLog(@"%@: IGNORING undefined key '%@' - can't set value '%@'", NSStringFromClass([self class]), key, value);
}

-(id) valueForUndefinedKey:(NSString *)key
{
	NSLog(@"%@: IGNORING value for undefined key '%@' - returning nil", NSStringFromClass([self class]), key);
	return nil;
}

@end
