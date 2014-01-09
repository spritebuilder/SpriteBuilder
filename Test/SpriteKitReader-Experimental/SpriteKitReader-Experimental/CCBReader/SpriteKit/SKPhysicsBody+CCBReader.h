//
//  SKPhysicsBody+CCBReader.h
//  SpriteKitReader-Experimental
//
//  Created by Steffen Itterheim on 09/01/14.
//  Copyright (c) 2014 Steffen Itterheim. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "CCBSpriteKitCompatibility.h"

@interface SKPhysicsBody (CCBReader)

+(instancetype) bodyWithPolygonFromPoints:(CGPoint*)points count:(NSUInteger)count cornerRadius:(CGFloat)cornerRadius;
+(instancetype) bodyWithCircleOfRadius:(CGFloat)radius andCenter:(CGPoint)center;

-(void) setType:(CCPhysicsBodyType)type;

@property CGFloat elasticity;

@end
