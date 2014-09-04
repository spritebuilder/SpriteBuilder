//
//  CCBPEffectRefraction.m
//  SpriteBuilder
//
//  Created by John Twigg on 7/8/14.
//
//

#import "CCBPEffectRefraction.h"
#import "CCNode+NodeInfo.h"
#import "CCBWriterInternal.h"
#import "CCBReaderInternal.h"
#import "AppDelegate.h"
#import "TexturePropertySetter.h"
#import "CocosScene.h"
#import "SceneGraph.h"


@interface CCBWriterInternal(Private)
+ (id) serializeSpriteFrame:(NSString*)spriteFile sheet:(NSString*)spriteSheetFile;
@end

@implementation CCBPEffectRefraction
{
	NSString * normalMapImageName;
	NSString * normalMapSheet;
	NSUInteger environmentUUID;
}
@synthesize UUID;
+(CCEffect<CCEffectProtocol>*)defaultConstruct
{
	return [[self alloc] init];
}



-(id)serialize
{
	return @[SERIALIZE_PROPERTY(refraction,Float),
			 @{@"name" : @"environment", @"type" : @"NodeReference", @"value": @(self.environment.UUID)},
			 @{@"name" : @"normalMap", @"type" : @"SpriteFrame", @"value": [CCBWriterInternal serializeSpriteFrame:normalMapImageName sheet:normalMapSheet]}
			 ];
}
-(void)deserialize:(NSArray *)properties
{
	
	DESERIALIZE_PROPERTY(refraction, floatValue);

	[properties findFirst:^BOOL(NSDictionary * dict, int idx) {\
		return [dict[@"name"] isEqualToString:@"environment"];\
	} complete:^(NSDictionary * dict, int idx) {
		environmentUUID =  [dict[@"value"] integerValue];
	}];
	
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

-(void)setEnvironment:(CCSprite *)environment
{
	[super setEnvironment:environment];
	
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
	if(environmentUUID == 0)
		self.environment = nil;
	else
	{
		self.environment = (CCSprite*)[SceneGraph findUUID:environmentUUID node:[SceneGraph instance].rootNode];
	}

}



@end
