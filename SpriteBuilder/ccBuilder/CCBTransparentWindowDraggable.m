//
//  CCBTransparentWindowDraggable.m
//  SpriteBuilder
//
//  Created by Viktor on 8/30/13.
//
//

#import "CCBTransparentWindowDraggable.h"

@implementation CCBTransparentWindowDraggable

- (void)mouseDown:(NSEvent *)theEvent
{    
    NSPoint currentLocation = [self convertBaseToScreen:[self mouseLocationOutsideOfEventStream]];
    
    offsetX = currentLocation.x - [self frame].origin.x;
    offsetY = currentLocation.y - [self frame].origin.y;
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    NSPoint currentLocation = [self convertBaseToScreen:[self mouseLocationOutsideOfEventStream]];
    
    NSPoint newOrigin = NSMakePoint(currentLocation.x - offsetX, currentLocation.y - offsetY);
    
    [self setFrameOrigin:newOrigin];
    
}

@end
