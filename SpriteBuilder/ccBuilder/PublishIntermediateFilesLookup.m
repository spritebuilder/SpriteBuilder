#import "PublishIntermediateFilesLookup.h"

@interface PublishIntermediateFilesLookup()

@property (nonatomic, strong) NSMutableDictionary *lookup;
@property (nonatomic) BOOL flattenPaths;

@end

@implementation PublishIntermediateFilesLookup

- (instancetype)initWithFlattenPaths:(BOOL)flattenPaths
{
    self = [super init];
    if (self)
    {
        self.flattenPaths = flattenPaths;
        self.lookup = [NSMutableDictionary dictionary];
    }

    return self;
}

- (void)addRenamingRuleFrom:(NSString *)src to:(NSString *)dst
{
    if (_flattenPaths)
    {
        src = [src lastPathComponent];
        dst = [dst lastPathComponent];
    }

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
