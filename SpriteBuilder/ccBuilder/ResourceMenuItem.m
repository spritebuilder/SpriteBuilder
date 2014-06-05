#import <MacTypes.h>
#import "ResourceMenuItem.h"

@interface ResourceMenuItem()

@property (nonatomic, strong, readwrite) NSArray *resources;

@end


@implementation ResourceMenuItem

- (instancetype)initWithTitle:(NSString *)title selector:(SEL)selector resources:(NSArray *)resources
{
    NSAssert(resources != nil, @"Resource menu item not making sense without a resource instance");

    self = [super initWithTitle:title action:selector keyEquivalent:@""];

    if (self)
    {
        self.resources = resources;
    }

    return self;
}

@end