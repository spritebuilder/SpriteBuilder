#import <Foundation/Foundation.h>


@interface ResourceMenuItem : NSMenuItem

@property (nonatomic, strong, readonly) NSArray *resources;

- (instancetype)initWithTitle:(NSString *)string selector:(SEL)selector resources:(NSArray *)resources;

@end