//
//  CCBPButton.m
//  SpriteBuilder
//
//  Created by Viktor on 9/25/13.
//
//

#import "CCBPButton.h"
#import "CCSprite9Slice.h"

@implementation CCBPButton

- (id) init
{
    self = [super init];
    if (!self) return NULL;
    
    self.userInteractionEnabled = NO;
    
    return self;
}

- (void)setMarginLeft:(float)marginLeft
{
    self.background.marginLeft = marginLeft;
}

- (void)setMarginRight:(float)marginRight
{
    self.background.marginRight = marginRight;
}

- (void)setMarginTop:(float)marginTop
{
    self.background.marginTop = marginTop;
}

- (float)marginBottom
{
    return self.background.marginBottom;
}

- (float)marginLeft
{
    return self.background.marginLeft;
}

- (float)marginRight
{
    return self.background.marginRight;
}

- (float)marginTop
{
    return self.background.marginTop;
}

- (void)setMarginBottom:(float)marginBottom
{
    self.background.marginBottom = marginBottom;
}


@end
