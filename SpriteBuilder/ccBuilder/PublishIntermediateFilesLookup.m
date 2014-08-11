#import "PublishIntermediateFilesLookup.h"

@interface PublishIntermediateFilesLookup()

@property (nonatomic, strong) NSMutableDictionary *lookup;

@end


@implementation PublishIntermediateFilesLookup

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.lookup = [NSMutableDictionary dictionary];
    }

    return self;
}

- (void)addRenamingRuleFrom:(NSString *)src to:(NSString *)dst
{
    NSAssert(src != nil, @"src must not be nil");
    NSAssert(dst != nil, @"dst must not be nil");

    if ([src isEqualToString:dst])
    {
        return;
    }

    [_lookup setObject:dst forKey:src];
}

- (BOOL)writeToFile:(NSString *)path
{
    return [_lookup writeToFile:path atomically:YES];
}

@end
