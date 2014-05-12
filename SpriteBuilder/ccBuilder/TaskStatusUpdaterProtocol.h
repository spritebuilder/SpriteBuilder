#import <Foundation/Foundation.h>

@protocol TaskStatusUpdaterProtocol <NSObject>

@optional
- (void)updateStatusText:(NSString *)text;

- (void)setProgress:(double)progress;

@end