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
	return @{@"refraction" : @(self.refraction),
			 @"environment" : @(self.environment.UUID),
			 @"normalMap" : (normalMapImageName ? normalMapImageName : @""),
			 @"normalMapSheet" : (normalMapSheet ? normalMapSheet : @"")};
}

-(void)deserialize:(NSDictionary*)dict
{
	self.refraction = [dict[@"refraction"] floatValue];
	
	environmentUUID = [dict[@"environment"] integerValue];
	
	
	normalMapImageName = dict[@"normalMap"];
	if([normalMapImageName isEqualToString:@""])
	{
		normalMapImageName = nil;
	}

	normalMapSheet = dict[@"normalMapSheet"];
	if([normalMapSheet isEqualToString:@""])
	{
		normalMapSheet = nil;
	}
	
	if(normalMapImageName && normalMapSheet)
		[TexturePropertySetter setSpriteFrameForNode:(CCNode*)self andProperty:@"normalMap" withFile:normalMapImageName andSheetFile:normalMapSheet];
	
	//self.normalMap = [CCBReaderInternal  //de[dict[@"normalMap"] ];
	
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
