//
//  CCSpriteFrameCache.m
//  SpriteKitReader-Experimental
//
//  Created by Steffen Itterheim on 13/01/14.
//  Copyright (c) 2014 Steffen Itterheim. All rights reserved.
//

#import "CCSpriteFrameCache.h"
#import "CCFileUtils.h"

@implementation CCSpriteFrameCache

#pragma mark Sprite Frame

+(instancetype) sharedSpriteFrameCache
{
	static CCSpriteFrameCache* sharedSpriteFrameCache = nil;
	if (sharedSpriteFrameCache == nil)
	{
		sharedSpriteFrameCache = [[CCSpriteFrameCache alloc] init];
	}
	return sharedSpriteFrameCache;
}

-(id) init
{
	self = [super init];
	if (self)
	{
		_atlases = [NSMutableDictionary dictionary];
	}
	return self;
}

-(void) loadSpriteFrameLookupDictionaryFromFile:(NSString*)file
{
	NSString *fullpath = [[CCFileUtils sharedFileUtils] fullPathForFilename:file];
	
	if (fullpath)
	{
		NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:fullpath];
		NSAssert1(dict, @"failed to load sprite frames plist '%@'", file);
		
		NSArray *spriteFrameFiles = [dict objectForKey:@"spriteFrameFiles"];
		for (NSString* spriteFrameFile in spriteFrameFiles)
        {
#pragma message "HACK! hardcoded path to plist file"
			NSString* atlasFile = [NSString stringWithFormat:@"Published-iOS/resources-phone/%@", spriteFrameFile];
			
			SKTextureAtlas* atlas = [SKTextureAtlas atlasNamed:atlasFile];
			NSLog(@"%@: %@", spriteFrameFile, atlas);
			[_atlases setObject:atlas forKey:spriteFrameFile];
        }
	}
}

-(SKTexture*) textureNamed:(NSString*)name
{
	SKTexture* texture = [_atlases objectForKey:name];
	return texture;
}

@end
