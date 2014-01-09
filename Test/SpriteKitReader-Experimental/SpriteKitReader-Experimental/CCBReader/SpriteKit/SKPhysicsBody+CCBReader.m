//
//  SKPhysicsBody+CCBReader.m
//  SpriteKitReader-Experimental
//
//  Created by Steffen Itterheim on 09/01/14.
//  Copyright (c) 2014 Steffen Itterheim. All rights reserved.
//

#import "SKPhysicsBody+CCBReader.h"
#import "CCBSpriteKitMacros.h"

@implementation SKPhysicsBody (CCBReader)

+(instancetype) bodyWithPolygonFromPoints:(CGPoint*)points count:(NSUInteger)count cornerRadius:(CGFloat)cornerRadius
{
	NOTIMPLEMENTED();
	return nil;
}

+(instancetype) bodyWithCircleOfRadius:(CGFloat)radius andCenter:(CGPoint)center
{
	return [SKPhysicsBody bodyWithCircleOfRadius:radius];
}

-(void) setType:(CCPhysicsBodyType)type
{
	if (type == CCPhysicsBodyTypeDynamic)
	{
		self.dynamic = YES;
	}
	else
	{
		self.dynamic = NO;
	}
}

-(void) setElasticity:(CGFloat)elasticity
{
	[self setRestitution:elasticity];
}

-(CGFloat) elasticity
{
	return self.elasticity;
}

@end
