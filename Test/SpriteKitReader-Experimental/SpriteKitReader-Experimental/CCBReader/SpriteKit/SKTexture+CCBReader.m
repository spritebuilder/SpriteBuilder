//
//  SKTexture+CCBReader.m
//  SpriteKitReader-Experimental
//
//  Created by Steffen Itterheim on 09/01/14.
//  Copyright (c) 2014 Steffen Itterheim. All rights reserved.
//

#import "SKTexture+CCBReader.h"
#import "CCSpriteFrameCache.h"

@implementation SKTexture (CCBReader)

+(instancetype) frameWithImageNamed:(NSString*)name
{
	return [SKTexture textureWithFile:name];
}

+(instancetype) textureWithFile:(NSString*)file
{
	SKTexture* texture = [SKTexture textureWithImageNamed:file];
	return texture;
}


@end
