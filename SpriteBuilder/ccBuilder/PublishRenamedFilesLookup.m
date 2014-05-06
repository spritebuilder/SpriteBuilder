#import "PublishRenamedFilesLookup.h"


@interface PublishRenamedFilesLookup ()

@property (nonatomic, strong) NSMutableDictionary *lookup;
@property (nonatomic) BOOL flattenPaths;

@end

@implementation PublishRenamedFilesLookup

- (id)initWithFlattenPaths:(BOOL)flattenPaths
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

- (BOOL)writeToFileAtomically:(NSString *)filePath
{
    NSMutableDictionary *plist = [NSMutableDictionary dictionary];

    NSMutableDictionary *metadata = [NSMutableDictionary dictionary];
    [metadata setObject:[NSNumber numberWithInt:1] forKey:@"version"];

    [plist setObject:metadata forKey:@"metadata"];
    [plist setObject:_lookup forKey:@"filenames"];

    return [plist writeToFile:filePath atomically:YES];
}

- (NSString *)description
{
    return [_lookup description];
}

@end