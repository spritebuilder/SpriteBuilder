//
//  CCBPSprite.m
//  SpriteBuilder
//
//  Created by Viktor on 12/17/13.
//
//

#import "CCBPSprite.h"
#import "NSArray+Query.h"
#import "CCEffect.h"
#import "CCEffectStack.h"
#import "AppDelegate.h"
#import "CCBDocument.h"

@implementation CCBPSprite
@synthesize effects;

-(void)addEffect:(CCEffect<EffectProtocol>*)effect
{
	[self willChangeValueForKey:@"effects"];
	
	NSMutableArray * mutableEffects = [NSMutableArray arrayWithArray:self.effects];
	[mutableEffects addObject:effect];
	self.effects = mutableEffects;
	[self didChangeValueForKey:@"effects"];
	[self reloadEffects];
	
}

-(void)removeEffect:(CCEffect<EffectProtocol>*)effect
{
	
	[self willChangeValueForKey:@"effects"];
	NSAssert([self.effects containsObject:effect], @"Does not contain the effect");
	
	NSMutableArray * mutableEffects = [NSMutableArray arrayWithArray:self.effects];
	[mutableEffects removeObject:effect];
	self.effects = mutableEffects;
	[self didChangeValueForKey:@"effects"];
	[self reloadEffects];
}

-(NSArray*)effectDescriptors{
	
	NSArray * effectDescriptors = [self.effects convertAll:^id(id<EffectProtocol> obj, int idx) {
		return obj.effectDescription;
	}];
	return effectDescriptors;
}

-(NSArray*)effects
{
	return effects;
}
-(void)setEffects:(NSArray *)lEffects
{
	self->effects = lEffects;
	[self reloadEffects];
}

-(void)reloadEffects
{
	self.effect = nil;
	
	if(self.effects.count == 0)
		return;
	
	self.effect = [[CCEffectStack alloc] initWithArray:self.effects];
	
}

-(void)postDeserializationFixup
{
	for(CCEffect * effect in  self.effects)
	{
		if([effect respondsToSelector:@selector(postDeserializationFixup)])
		{
			[effect performSelector:@selector(postDeserializationFixup) withObject:nil];
		}
	}
}

-(void)postCopyFixup
{
	for(CCEffect<EffectProtocol> * effect in  self.effects)
	{
		effect.UUID = [[AppDelegate appDelegate].currentDocument getAndIncrementUUID];
	}

}
@end
