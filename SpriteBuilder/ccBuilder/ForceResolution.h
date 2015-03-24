//
//  ForceHighRes.h
//  SpriteBuilder
//
//  Created by Scott Lembcke on 3/24/15.
//
//

#import "CCTexture.h"
#import "CCSpriteFrame.h"
#import "CCSprite.h"
#import "CCLabelBMFont.h"


@interface CCTexture(ForceResolution)

+(CGFloat)SBWidgetScale;

+(instancetype)textureWithFile:(NSString*)file contentScale:(CGFloat)contentScale;

@end


@interface CCSpriteFrame(ForceResolution)

+(instancetype) frameWithImageNamed:(NSString*)imageName contentScale:(CGFloat)contentScale;

@end


@interface CCSprite(ForceResolution)

+(instancetype)spriteWithImageNamed:(NSString *)imageName contentScale:(CGFloat)contentScale;

@end


@interface CCLabelBMFont(ForceResolution)

+(instancetype)labelWithString:(NSString *)string fntFile:(NSString *)fntFile width:(float)width alignment:(CCTextAlignment)alignment contentScale:(CGFloat)contentScale;

@end
