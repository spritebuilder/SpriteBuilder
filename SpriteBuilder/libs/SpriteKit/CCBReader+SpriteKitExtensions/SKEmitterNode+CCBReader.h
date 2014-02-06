//
//  SKEmitterNode+CCBReader.h
//  SpriteKitReader-Experimental
//
//  Created by Steffen Itterheim on 17/01/14.
//  Copyright (c) 2014 Steffen Itterheim. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "CCBSpriteKitCompatibility.h"

@interface SKEmitterNode (CCBReader)

@property (nonatomic) SKTexture* texture;
@property (nonatomic) CGFloat duration;
@property (nonatomic) CGFloat emissionRate;
@property (nonatomic) CGFloat life;
@property (nonatomic) CGFloat lifeVar;

@property (nonatomic) ccBlendFunc blendFunc;

@end
