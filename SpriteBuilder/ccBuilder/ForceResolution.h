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


// These categories are used to load files with an explicit resolution.
// They should be loaded from -1x images so that CCFileUtils doesn't apply search rules or contentScales to the files.
// After the textures are loaded, they have an explicit contentScale applied to them.
// This is not generally texture cache safe, but SpriteBuilder doesn't use the texture cache in the normal way anyway.

@interface CCTexture(ForceResolution)

// Content scale widgets should load as to have a 2x content scale compared to Apple's UI points.
// (Rulers, resizing handles, etc)
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
