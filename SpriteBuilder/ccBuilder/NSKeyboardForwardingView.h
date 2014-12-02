#import <Foundation/Foundation.h>

@protocol KeyboardEventHandler

- (void)keyDown:(NSEvent *)theEvent;

- (void)keyUp:(NSEvent *)theEvent;

- (void)interpretKeyEvents:(NSArray *)eventArray;

@end


@interface NSKeyboardForwardingView : NSView

@property(nonatomic, weak) IBOutlet NSObject<KeyboardEventHandler> *delegate;
@end