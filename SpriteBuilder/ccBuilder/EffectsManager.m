//
//  EffectsManager.m
//  SpriteBuilder
//
//  Created by John Twigg on 6/23/14.
//
//

#import "EffectsManager.h"
#import "CCBPEffectBrightness.h"
#import "CCEffectContrast.h"
#import "CCEffectGlow.h"
#import "CCEffectPixellate.h"
#import "CCEffectSaturation.h"
#import "NSArray+Query.h"
#import "EffectBrightnessControl.h"

@implementation EffectDescription

-(CCEffect*)constructDefault
{

	Class classType = NSClassFromString(self.className);
	NSAssert([classType conformsToProtocol:@protocol(EffectProtocol)], @"Should conform to Effect Protocol");

	Class<EffectProtocol> protocolClass = (Class<EffectProtocol>)classType;
	
	return [protocolClass defaultConstruct];;
}
@end

@implementation EffectsManager

+(NSArray*)effects
{
	
	NSMutableArray * effectDescriptions = [NSMutableArray new];
	
	{
		EffectDescription * effectDescription = [[EffectDescription alloc] init];
		effectDescription.title = @"Brightness";
		effectDescription.description = @"Makes things bright";
		effectDescription.imageName = @"notes-bg.png";
		effectDescription.className = NSStringFromClass([CCBPEffectBrightness class]);
		effectDescription.viewController = NSStringFromClass([EffectBrightnessControl class]);
		
		[effectDescriptions addObject:effectDescription];
	}
	
	{
		EffectDescription * effectDescription = [[EffectDescription alloc] init];
		effectDescription.title = @"Contrast";
		effectDescription.description = @"Makes things contrast";
		effectDescription.imageName = @"";
		effectDescription.className = NSStringFromClass([CCEffectContrast class]);
		
		
		
		[effectDescriptions addObject:effectDescription];
	}
	
	{
		EffectDescription * effectDescription = [[EffectDescription alloc] init];
		effectDescription.title = @"Pixellate";
		effectDescription.description = @"Makes things pixellate";
		effectDescription.imageName = @"";
		effectDescription.className = NSStringFromClass([CCEffectPixellate class]);
				
		[effectDescriptions addObject:effectDescription];
	}
	
	{
		EffectDescription * effectDescription = [[EffectDescription alloc] init];
		effectDescription.title = @"Saturation";
		effectDescription.description = @"Makes things saturate";
		effectDescription.imageName = @"";
		effectDescription.className = NSStringFromClass([CCEffectSaturation class]);
		

		
		[effectDescriptions addObject:effectDescription];
	}
	
	return effectDescriptions;
}

+(EffectDescription*)effectByClassName:(NSString*)className
{
	return [[self effects] findFirst:^BOOL(EffectDescription * effectDescription, int idx) {
		return [effectDescription.className isEqualToString:className];
	}];
}

@end
