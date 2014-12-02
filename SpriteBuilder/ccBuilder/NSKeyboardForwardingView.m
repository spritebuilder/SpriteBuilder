#import "NSKeyboardForwardingView.h"


@implementation NSKeyboardForwardingView


- (void)keyDown:(NSEvent *)theEvent
{
    [_delegate keyDown:theEvent];
}

- (void)keyUp:(NSEvent *)theEvent
{
    [_delegate keyUp:theEvent];
}

- (void)interpretKeyEvents:(NSArray *)eventArray
{
    [_delegate interpretKeyEvents:eventArray];
}

@end