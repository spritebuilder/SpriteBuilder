#import <Foundation/Foundation.h>

@class CCBWarnings;
@class CCBPublisher;

@protocol PublishingFinishedDelegate <NSObject>

- (void)publisher:(CCBPublisher *)publisher finishedWithWarnings:(CCBWarnings *)warnings;

@end