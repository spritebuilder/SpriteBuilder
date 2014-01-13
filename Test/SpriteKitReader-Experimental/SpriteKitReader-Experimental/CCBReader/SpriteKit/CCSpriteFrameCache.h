//
//  CCSpriteFrameCache.h
//  SpriteKitReader-Experimental
//
//  Created by Steffen Itterheim on 13/01/14.
//  Copyright (c) 2014 Steffen Itterheim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SpriteKit/SpriteKit.h>

@interface CCSpriteFrameCache : NSObject
{
	@private
	NSMutableDictionary* _atlases;
}

+(instancetype) sharedSpriteFrameCache;
-(void) loadSpriteFrameLookupDictionaryFromFile:(NSString*)file;
-(SKTexture*) textureNamed:(NSString*)name;

@end
