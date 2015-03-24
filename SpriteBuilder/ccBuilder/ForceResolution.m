//
//  ForceHighRes.m
//  SpriteBuilder
//
//  Created by Scott Lembcke on 3/24/15.
//
//

#import "ForceResolution.h"
#import "CCSetup.h"
#import "AppDelegate.h"

@implementation CCTexture(ForceResolution)

+(CGFloat)SBWidgetScale
{
    // Widgets always load retina quality assets even on non-retina Macs.
    AppDelegate *delegate = (AppDelegate *)[NSApplication sharedApplication].delegate;
    return 2.0*[CCSetup sharedSetup].contentScale/delegate.windowContentScaleFactor;
}

+(instancetype)textureWithFile:(NSString*)file contentScale:(CGFloat)contentScale;
{
    CCTexture *texture = [CCTexture textureWithFile:file];
    texture.contentScale = contentScale;
    return texture;
}

@end


@implementation CCSpriteFrame(ForceResolution)

+(instancetype) frameWithImageNamed:(NSString*)imageName contentScale:(CGFloat)contentScale
{
    CCTexture *texture = [CCTexture textureWithFile:imageName contentScale:contentScale];
    texture.contentScale = contentScale;
    return texture.spriteFrame;
}

@end


@implementation CCSprite(ForceResolution)


+(instancetype)spriteWithImageNamed:(NSString *)imageName contentScale:(CGFloat)contentScale;
{
    return [self spriteWithTexture:[CCTexture textureWithFile:imageName contentScale:contentScale]];
}

@end


@implementation CCLabelBMFont(ForceResolution)

+(instancetype)labelWithString:(NSString *)string fntFile:(NSString *)fntFile width:(float)width alignment:(CCTextAlignment)alignment contentScale:(CGFloat)contentScale
{
    CCLabelBMFont *label = [self labelWithString:string fntFile:fntFile width:width alignment:alignment];
    
    // This one is more of a nasty hack. (Eww. Sorry!)
    // Need to grab the private texture ivar out of the label to modify it's content scale.
    CCTexture *texture = [label valueForKey:@"_texture"];
    texture.contentScale = contentScale;
    
    return label;
}

@end
