/*
 * SpriteBuilder: http://www.spritebuilder.org
 *
 * Copyright (c) 2009 Jason Booth
 * Copyright (c) 2009 Robert J Payne
 * Copyright (c) 2008-2010 Ricardo Quesada
 * Copyright (c) 2011 Zynga Inc.
 * Copyright (c) 2014 Apportable Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

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
		_spriteFrameFileLookup = [NSMutableDictionary dictionary];
	}
	return self;
}

-(void) loadSpriteFrameLookupDictionaryFromFile:(NSString*)file
{
	NSString *fullpath = [[CCFileUtils sharedFileUtils] fullPathForFilenameIgnoringResolutions:file];
	if (fullpath)
	{
		NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:fullpath];
		NSAssert1(dict, @"failed to load sprite frames plist '%@'", file);

		NSDictionary *metadata = [dict objectForKey:@"metadata"];
		NSInteger version = [[metadata objectForKey:@"version"] integerValue];
		NSAssert2(version == 1, @"CCSpriteFrameCache: filename lookup dictionary has unsupported version %ld for file: %@", (long)version, file);
		
		NSArray *spriteFrameFiles = [dict objectForKey:@"spriteFrameFiles"];
		for (NSString* spriteFrameFile in spriteFrameFiles)
        {
            [self registerSpriteFramesFile:spriteFrameFile];

			/*
			NSString* atlasFile = [NSString stringWithFormat:@"Published-iOS/resources-phone/%@", spriteFrameFile];
			
			SKTextureAtlas* atlas = [SKTextureAtlas atlasNamed:atlasFile];
			NSLog(@"%@: %@", spriteFrameFile, atlas);
			[_atlases setObject:atlas forKey:spriteFrameFile];
			 */
        }
	}
}

-(void) registerSpriteFramesFile:(NSString*)plist
{
    NSString *path = [[CCFileUtils sharedFileUtils] fullPathForFilename:plist];
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:path];
    
    NSDictionary *metadataDict = [dictionary objectForKey:@"metadata"];
	NSDictionary *framesDict = [dictionary objectForKey:@"frames"];
    
	int format = 0;
    
	// get the format
	if (metadataDict != nil)
	{
		format = [[metadataDict objectForKey:@"format"] intValue];
	}
    
	// check the format
	NSAssert1(format >= 0 && format <= 3, @"format %ld is not supported for CCSpriteFrameCache addSpriteFramesWithDictionary:textureFilename:", (long)format);
    
    for (NSString *frameDictKey in framesDict)
    {
        [_spriteFrameFileLookup setObject:plist forKey:frameDictKey];
    }
}

-(SKTexture*) textureNamed:(NSString*)name
{
	SKTexture* texture = [_atlases objectForKey:name];
	return texture;
}

@end
