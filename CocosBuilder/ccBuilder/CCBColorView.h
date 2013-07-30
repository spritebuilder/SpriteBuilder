//
//  CCBColorView.h
//  CocosBuilder
//
//  Created by Viktor on 7/26/13.
//
//

#import <Cocoa/Cocoa.h>

@interface CCBColorView : NSView

@property (nonatomic,copy) NSColor* backgroundColor;
@property (nonatomic,copy) NSColor* borderColor;
@property (nonatomic,assign) float radius;

@end
