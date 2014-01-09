//
//  SKNode+CCBReader.h
//  SpriteKitReader-Experimental
//
//  Created by Steffen Itterheim on 09/01/14.
//  Copyright (c) 2014 Steffen Itterheim. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "CCBSpriteKitCompatibility.h"

@interface SKNode (CCBReader)

@property id userObject;
@property (readonly) CGSize contentSize;
@property CGFloat rotation;
@property CGFloat skewX;
@property CGFloat skewY;
@property BOOL visible;
@property CCPositionType positionType;
@property SKTexture* spriteFrame;

-(CGFloat) scale;

@end
