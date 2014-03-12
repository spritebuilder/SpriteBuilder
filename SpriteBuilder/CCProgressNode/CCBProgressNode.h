//
//  CCProgressTimer.h
//  CCProgressTimer
//
//  Created by user-i134 on 8/5/13.
//
//

#import "cocos2d.h"

@interface CCBProgressNode : CCProgressNode
{
}

@property (nonatomic, retain) CCSpriteFrame *spriteFrame;
@property (nonatomic, assign) ccBlendFunc blendFunc;
@property (nonatomic, assign) BOOL flipX;
@property (nonatomic, assign) BOOL flipY;

@end
