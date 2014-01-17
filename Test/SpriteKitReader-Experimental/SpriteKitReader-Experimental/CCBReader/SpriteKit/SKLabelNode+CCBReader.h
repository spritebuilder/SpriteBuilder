//
//  SKLabelNode+CCBReader.h
//  SpriteKitReader-Experimental
//
//  Created by Steffen Itterheim on 17/01/14.
//  Copyright (c) 2014 Steffen Itterheim. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "CCBSpriteKitCompatibility.h"

@interface SKLabelNode (CCBReader)

@property (nonatomic) NSString* string;
@property (nonatomic) CCColor* color;
@property (nonatomic) CCColor* ccb_fontColor;
@end
