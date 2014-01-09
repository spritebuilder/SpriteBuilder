//
//  SKTexture+CCBReader.m
//  SpriteKitReader-Experimental
//
//  Created by Steffen Itterheim on 09/01/14.
//  Copyright (c) 2014 Steffen Itterheim. All rights reserved.
//

#import "SKTexture+CCBReader.h"

@implementation SKTexture (CCBReader)

+(instancetype) frameWithImageNamed:(NSString*)name
{
	NOTIMPLEMENTED();
	return nil;
}

+(instancetype) textureWithFile:(NSString*)file
{
	return [SKTexture textureWithImageNamed:file];
}


@end
