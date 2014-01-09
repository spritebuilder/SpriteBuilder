//
//  SKTexture+CCBReader.h
//  SpriteKitReader-Experimental
//
//  Created by Steffen Itterheim on 09/01/14.
//  Copyright (c) 2014 Steffen Itterheim. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "CCBSpriteKitMacros.h"

@interface SKTexture (CCBReader)

+(instancetype) frameWithImageNamed:(NSString*)name;
+(instancetype) textureWithFile:(NSString*)file;

@end
