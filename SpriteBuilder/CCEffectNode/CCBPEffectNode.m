//
//  CCBPLayerColor.m
//  SpriteBuilder
//
//  Created by Viktor on 9/12/13.
//
//

#import "CCBPEffectNode.h"
#import "CCEffectStack.h"


@interface CCBPEffectNode()
@property (nonatomic) NSMutableArray * effectDescriptors;
@end

@implementation CCBPEffectNode
@synthesize effects;

-(id)init
{
	self = [super init];
	if(self != nil)
	{
		self.effectDescriptors = [NSMutableArray new];
	}
	return self;
}

-(void)addEffect:(EffectDescription*)effectDescription
{
	[self willChangeValueForKey:@"effects"];
	[_effectDescriptors addObject:effectDescription];
	[self didChangeValueForKey:@"effects"];
	[self reloadEffects];
}

-(void)removeEffect:(EffectDescription*)effectDescription
{
	[self willChangeValueForKey:@"effects"];
	[_effectDescriptors removeObject:effectDescription];
	[self didChangeValueForKey:@"effects"];
	[self reloadEffects];
}

-(void)reloadEffects
{
	self.effect = nil;
	
	if(_effectDescriptors.count == 0)
		return;
	
	
	NSMutableArray * _effects = [NSMutableArray new];
	
	for (EffectDescription * effectDescription in _effectDescriptors) {

		//Temp code.
		CCEffect * tempEffect = [effectDescription constructDefault];
		[_effects  addObject:tempEffect];
	}
	
    self.effects = _effects;
	self.effect = [[CCEffectStack alloc] initWithEffects:_effects];
	
}

@end
