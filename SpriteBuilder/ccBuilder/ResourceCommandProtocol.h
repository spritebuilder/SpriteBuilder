#import <Foundation/Foundation.h>

@protocol ResourceCommandProtocol <NSObject>

// Command will be applied to these resources
@property (nonatomic, strong) NSArray *resources;

- (void)execute;

@end