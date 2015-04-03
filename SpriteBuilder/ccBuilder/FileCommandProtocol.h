#import <Foundation/Foundation.h>

@protocol FileCommandProtocol <NSObject>

- (BOOL)execute:(NSError **)error;

- (BOOL)undo:(NSError **)error;

@optional
- (void)tidyUp;

@end