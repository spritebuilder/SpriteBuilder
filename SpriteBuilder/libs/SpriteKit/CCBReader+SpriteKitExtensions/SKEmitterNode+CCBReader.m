//
//  SKEmitterNode+CCBReader.m
//  SpriteKitReader-Experimental
//
//  Created by Steffen Itterheim on 17/01/14.
//  Copyright (c) 2014 Steffen Itterheim. All rights reserved.
//

#import "SKEmitterNode+CCBReader.h"

@implementation SKEmitterNode (CCBReader)

-(void) setTexture:(SKTexture *)texture
{
	self.particleTexture = texture;
}
-(SKTexture*) texture
{
	return self.particleTexture;
}

-(void) setDuration:(CGFloat)duration
{
	if (duration <= 0.0)
	{
		self.numParticlesToEmit = 0.0;
	}
	else
	{
		self.numParticlesToEmit = duration * self.particleBirthRate;
	}
}
-(CGFloat) duration
{
	return self.numParticlesToEmit / self.particleBirthRate;
}

-(void) setEmissionRate:(CGFloat)emissionRate
{
	self.particleBirthRate = emissionRate;
}
-(CGFloat) emissionRate
{
	return self.particleBirthRate;
}

-(void) setLife:(CGFloat)life
{
	self.particleLifetime = life;
}
-(CGFloat) life
{
	return self.particleLifetime;
}

-(void) setLifeVar:(CGFloat)lifeVar
{
	self.particleLifetimeRange = lifeVar;
}
-(CGFloat) lifeVar
{
	return self.particleLifetimeRange;
}

-(void) setBlendFunc:(ccBlendFunc)blendFunc
{
	self.particleBlendMode = SKBlendModeAlpha;
}
-(ccBlendFunc) blendFunc
{
	return (ccBlendFunc){0, 0};
}

@end
