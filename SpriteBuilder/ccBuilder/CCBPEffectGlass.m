//
//  CCBPEffectGlass.m
//  SpriteBuilder
//
//  Created by John Twigg on 7/28/14.
//
//

#import "CCBPEffectGlass.h"
#import "CCNode+NodeInfo.h"
#import "CCBWriterInternal.h"
#import "CCBReaderInternal.h"
#import "AppDelegate.h"
#import "TexturePropertySetter.h"
#import "CocosScene.h"
#import "SceneGraph.h"


@implementation CCBPEffectGlass
{
	NSString * normalMapImageName;
	NSString * normalMapSheet;
	
	NSUInteger reflectionEnvironmentUUID;
	NSUInteger refractionEnvironmentUUID;
}

@synthesize UUID;

+(CCEffect<CCEffectProtocol>*)defaultConstruct
{
	return [[self alloc] init];
}



-(id)serialize
{
	return @[SERIALIZE_PROPERTY(refraction,Float),
			 SERIALIZE_PROPERTY(shininess,Float),
			 SERIALIZE_PROPERTY(fresnelBias,Float),
			 SERIALIZE_PROPERTY(fresnelPower,Float),
			 @{@"name" : @"reflectionEnvironment", @"type" : @"NodeReference", @"value": @(self.reflectionEnvironment.UUID)},
			 @{@"name" : @"refractionEnvironment", @"type" : @"NodeReference", @"value": @(self.refractionEnvironment.UUID)},
			 @{@"name" : @"normalMap", @"type" : @"SpriteFrame", @"value": [CCBWriterInternal serializeSpriteFrame:normalMapImageName sheet:normalMapSheet]}
			 ];
}


-(void)deserialize:(NSArray *)properties
{
	
	DESERIALIZE_PROPERTY(refraction, floatValue);
	DESERIALIZE_PROPERTY(shininess, floatValue);
	DESERIALIZE_PROPERTY(fresnelBias, floatValue);
	DESERIALIZE_PROPERTY(fresnelPower, floatValue);
	
	//reflectionEnvironment
	[properties findFirst:^BOOL(NSDictionary * dict, int idx) {\
		return [dict[@"name"] isEqualToString:@"reflectionEnvironment"];\
	} complete:^(NSDictionary * dict, int idx) {
		reflectionEnvironmentUUID =  [dict[@"value"] integerValue];
	}];
	
	//refractionEnvironment
	[properties findFirst:^BOOL(NSDictionary * dict, int idx) {\
		return [dict[@"name"] isEqualToString:@"refractionEnvironment"];\
	} complete:^(NSDictionary * dict, int idx) {
		refractionEnvironmentUUID =  [dict[@"value"] integerValue];
	}];
	
	//normalMap
	[properties findFirst:^BOOL(NSDictionary * dict, int idx) {\
		return [dict[@"name"] isEqualToString:@"normalMap"];\
	} complete:^(NSDictionary * dict, int idx) {
		
		NSArray * serializedValue = dict[@"value"];
		
		NSString* spriteSheetFile = [serializedValue objectAtIndex:0];
		NSString* spriteFile = [serializedValue objectAtIndex:1];
		if (!spriteSheetFile || [spriteSheetFile isEqualToString:@""])
		{
			spriteSheetFile = kCCBUseRegularFile;
		}
		
		normalMapImageName = spriteFile;
		normalMapSheet = spriteSheetFile;
		
		[TexturePropertySetter setSpriteFrameForNode:(CCNode*)self andProperty:@"normalMap" withFile:spriteFile andSheetFile:spriteSheetFile];
		
	}];
	
}


-(EffectDescription*)effectDescription
{
	return [EffectsManager effectByClassName: NSStringFromClass([self class])];
}

-(void)setRefractionEnvironment:(CCSprite *)refractionEnvironment
{
	[super setRefractionEnvironment:refractionEnvironment];
	
	[[AppDelegate appDelegate] refreshProperty:@"effects"];
}


-(void)setReflectionEnvironment:(CCSprite *)reflectionEnvironment
{
	[super setReflectionEnvironment:reflectionEnvironment];
	
	[[AppDelegate appDelegate] refreshProperty:@"effects"];
}


- (void) setExtraProp:(id)prop forKey:(NSString *)key
{
	
	if([key isEqualToString:@"normalMap"])
	{
		normalMapImageName = prop;
		
	}
	if([key isEqualToString:@"normalMapSheet"])
	{
		normalMapSheet = prop;
	}
}

- (id) extraPropForKey:(NSString *)key
{
    if([key isEqualToString:@"normalMap"])
	{
		return normalMapImageName;
		
	}
	if([key isEqualToString:@"normalMapSheet"])
	{
		return normalMapSheet;
	}
	return nil;
}

-(void)postDeserializationFixup
{
	if(reflectionEnvironmentUUID == 0)
		self.reflectionEnvironment = nil;
	else
	{
		self.reflectionEnvironment =(CCSprite*)[SceneGraph findUUID:reflectionEnvironmentUUID node:[SceneGraph instance].rootNode];
	}
	
	if(refractionEnvironmentUUID == 0)
		self.refractionEnvironment = nil;
	else
	{
		self.refractionEnvironment =(CCSprite*)[SceneGraph findUUID:refractionEnvironmentUUID node:[SceneGraph instance].rootNode];
	}
	
}




@end
