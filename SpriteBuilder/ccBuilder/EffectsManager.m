//
//  EffectsManager.m
//  SpriteBuilder
//
//  Created by John Twigg on 6/23/14.
//
//

#import "EffectsManager.h"
#import "CCBPEffectBrightness.h"
#import "CCBPEffectContrast.h"
#import "CCBPEffectPixelate.h"
#import "CCBPEffectSaturation.h"
#import "CCBPEffectHue.h"
#import "CCBPEffectBloom.h"
#import "CCBPEffectRefraction.h"
#import "NSArray+Query.h"
#import "EffectBrightnessControl.h"
#import "EffectContrastControl.h"
#import "EffectPixelateControl.h"
#import "EffectSaturationControl.h"
#import "EffectBloomControl.h"
#import "EffectRefractionControl.h"
#import "EffectHueControl.h"
#import "AppDelegate.h"
#import "CCBDocument.h"
#import "CCBPEffectReflection.h"
#import "CCBPEffectGlass.h"
#import "EffectGlassControl.h"
#import "EffectReflectionControl.h"
#import "CCBPEffectBlur.h"
#import "EffectBlurControl.h"
#import "CCBPEffectLighting.h"
#import "EffectLightingControl.h"
#import "EffectOutlineControl.h"
#import "CCBPEffectColorChannelOffset.h"
#import "EffectColorChannelOffsetControl.h"


@implementation CCNode(Effects)

-(CCEffect<EffectProtocol>*)findEffect:(NSUInteger)uuid
{
	if([self conformsToProtocol:@protocol(CCEffectNodeProtocol)])
	{
		CCNode<CCEffectNodeProtocol>* effectNode =(CCNode<CCEffectNodeProtocol>*) self;
		
		for (CCEffect<EffectProtocol>*effect in effectNode.effects) {
			if(effect.UUID == uuid)
				return effect;
		}
	}

	for (CCNode * child in self.children) {
		CCEffect<EffectProtocol>* childEffect = [child findEffect:uuid];
		if(childEffect)
			return childEffect;
	}
	
	return nil;
}

@end

@implementation EffectDescription

-(CCEffect<EffectProtocol>*)constructDefault
{

	Class classType = NSClassFromString(self.className);
	NSAssert([classType conformsToProtocol:@protocol(EffectProtocol)], @"Should conform to Effect Protocol");

	Class<EffectProtocol> protocolClass = (Class<EffectProtocol>)classType;
	
	CCEffect<EffectProtocol> *effect = [protocolClass defaultConstruct];

	effect.UUID = [[AppDelegate appDelegate].currentDocument getAndIncrementUUID];

	return effect;
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
		effectDescription.imageName = @"effect-brightness.png";
		effectDescription.className = NSStringFromClass([CCBPEffectBrightness class]);
		effectDescription.baseClass = @"CCEffectBrightness";
		effectDescription.viewController = NSStringFromClass([EffectBrightnessControl class]);
        effectDescription.group = 0;
		
		[effectDescriptions addObject:effectDescription];
	}
	
	{
		EffectDescription * effectDescription = [[EffectDescription alloc] init];
		effectDescription.title = @"Contrast";
		effectDescription.description = @"Makes things contrast";
		effectDescription.imageName = @"effect-contrast.png";
		effectDescription.className = NSStringFromClass([CCBPEffectContrast class]);
		effectDescription.baseClass = @"CCEffectContrast";
		effectDescription.viewController = NSStringFromClass([EffectContrastControl class]);
        effectDescription.group = 0;
        
		[effectDescriptions addObject:effectDescription];
	}
    
    {
        EffectDescription * effectDescription = [[EffectDescription alloc] init];
        effectDescription.title = @"Saturation";
        effectDescription.description = @"Makes things saturate";
        effectDescription.imageName = @"effect-saturation.png";
        effectDescription.baseClass = @"CCEffectSaturation";
        effectDescription.className = NSStringFromClass([CCBPEffectSaturation class]);
        effectDescription.viewController = NSStringFromClass([EffectSaturationControl class]);
        effectDescription.group = 0;
        
        [effectDescriptions addObject:effectDescription];
    }
    
    {
        EffectDescription * effectDescription = [[EffectDescription alloc] init];
        effectDescription.title = @"Hue";
        effectDescription.description = @"Makes things hueier";
        effectDescription.imageName = @"effect-hue.png";
        effectDescription.baseClass = @"CCEffectHue";
        effectDescription.className = NSStringFromClass([CCBPEffectHue class]);
        effectDescription.viewController = NSStringFromClass([EffectHueControl class]);
        effectDescription.group = 0;
        
        [effectDescriptions addObject:effectDescription];
    }
	
	{
		EffectDescription * effectDescription = [[EffectDescription alloc] init];
		effectDescription.title = @"Pixellate";
		effectDescription.description = @"Makes things pixelate";
		effectDescription.imageName = @"effect-pixelate.png";
		effectDescription.className = NSStringFromClass([CCBPEffectPixelate class]);
		effectDescription.baseClass = @"CCEffectPixellate";
		effectDescription.viewController = NSStringFromClass([EffectPixelateControl class]);
        effectDescription.group = 1;
        
		[effectDescriptions addObject:effectDescription];
	}
	
	{
        EffectDescription * effectDescription = [[EffectDescription alloc] init];
        effectDescription.title = @"Color Channel Offset";
        effectDescription.description = @"Shifts color channels";
        effectDescription.imageName = @"effect-color-channel-offset.png";
        effectDescription.className = NSStringFromClass([CCBPEffectColorChannelOffset class]);
        effectDescription.baseClass = @"CCEffectColorChannelOffset";
        effectDescription.viewController = NSStringFromClass([EffectColorChannelOffsetControl class]);
        effectDescription.group = 1;
        
        [effectDescriptions addObject:effectDescription];
	}
	
	{
		EffectDescription * effectDescription = [[EffectDescription alloc] init];
		effectDescription.title = @"Blur";
		effectDescription.description = @"Makes things blur";
		effectDescription.imageName = @"effect-blur.png";
		effectDescription.baseClass = @"CCEffectBlur";
		effectDescription.className = NSStringFromClass([CCBPEffectBlur class]);
		effectDescription.viewController = NSStringFromClass([EffectBlurControl class]);
        effectDescription.group = 1;
        
		[effectDescriptions addObject:effectDescription];
	}
	
	{
		EffectDescription * effectDescription = [[EffectDescription alloc] init];
		effectDescription.title = @"Bloom";
		effectDescription.description = @"Makes things bloom";
		effectDescription.imageName = @"effect-bloom.png";
		effectDescription.className = NSStringFromClass([CCBPEffectBloom class]);
		effectDescription.baseClass = @"CCEffectBloom";
		effectDescription.viewController = NSStringFromClass([EffectBloomControl class]);
        effectDescription.group = 1;
        
		[effectDescriptions addObject:effectDescription];
	}
	

	{
		EffectDescription * effectDescription = [[EffectDescription alloc] init];
		effectDescription.title = @"Refraction";
		effectDescription.description = @"Makes things refract";
		effectDescription.imageName = @"effect-refraction";
		effectDescription.className = NSStringFromClass([CCBPEffectRefraction class]);
		effectDescription.baseClass = @"CCEffectRefraction";
		effectDescription.viewController = NSStringFromClass([EffectRefractionControl class]);
        effectDescription.group = 2;
        
		[effectDescriptions addObject:effectDescription];
		
	}
	
	
	{
		EffectDescription * effectDescription = [[EffectDescription alloc] init];
		effectDescription.title = @"Reflection";
		effectDescription.description = @"Makes things reflect";
		effectDescription.imageName = @"effect-reflection";
		effectDescription.className = NSStringFromClass([CCBPEffectReflection class]);
		effectDescription.baseClass = @"CCEffectReflection";
        effectDescription.viewController = NSStringFromClass([EffectReflectionControl class]);
        effectDescription.group = 2;
        
		[effectDescriptions addObject:effectDescription];
		
	}
	
	{
		EffectDescription * effectDescription = [[EffectDescription alloc] init];
		effectDescription.title = @"Glass";
		effectDescription.description = @"Makes things look like glass";
		effectDescription.imageName = @"effect-glass";
		effectDescription.className = NSStringFromClass([CCBPEffectGlass class]);
		effectDescription.baseClass = @"CCEffectGlass";
        effectDescription.viewController = NSStringFromClass([EffectGlassControl class]);
        effectDescription.group = 2;
        
		[effectDescriptions addObject:effectDescription];
	}

	{
		EffectDescription * effectDescription = [[EffectDescription alloc] init];
		effectDescription.title = @"Lighting";
		effectDescription.description = @"Applies lighting to things";
		effectDescription.imageName = @"effect-lighting";
		effectDescription.className = NSStringFromClass([CCBPEffectLighting class]);
		effectDescription.baseClass = @"CCEffectLighting";
		effectDescription.viewController = NSStringFromClass([EffectLightingControl class]);
		effectDescription.group = 3;
        
		[effectDescriptions addObject:effectDescription];
	}
    
    /*
    {
        EffectDescription * effectDescription = [[EffectDescription alloc] init];
        effectDescription.title = @"Outline";
        effectDescription.description = @"Adds an outline";
        effectDescription.imageName = @"effect-outline.png";
        effectDescription.className = NSStringFromClass([CCBPEffectOutline class]);
        effectDescription.baseClass = @"CCEffectOutline";
        effectDescription.viewController = NSStringFromClass([EffectOutlineControl class]);
        effectDescription.group = 1;
        
        [effectDescriptions addObject:effectDescription];
    }
     */

	return effectDescriptions;
}

+(EffectDescription*)effectByClassName:(NSString*)className
{
	return [[self effects] findFirst:^BOOL(EffectDescription * effectDescription, int idx) {
		return [effectDescription.className isEqualToString:className];
	}];
}

@end
