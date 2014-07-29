#import "PublishFileLookupProtocol.h"
#import "PublishRenamedFilesLookup.h"

@interface PublishRenamedFilesLookup ()

@property (nonatomic, strong) NSMutableDictionary *lookup;
@property (nonatomic, strong) NSMutableSet *intermediateLookupPaths;

@end


@implementation PublishRenamedFilesLookup

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        self.lookup = [NSMutableDictionary dictionary];
        self.intermediateLookupPaths = [NSMutableSet set];
    }

    return self;
}

- (void)addRenamingRuleFrom:(NSString *)src to:(NSString *)dst
{
    if ([src isEqualToString:dst])
    {
        return;
    }

    [_lookup setObject:dst forKey:src];
}

- (BOOL)writeToFileAtomically:(NSString *)filePath
{
    NSMutableDictionary *intermediateLookups = [self loadAndMergeIntermediateLookups];
    [_lookup addEntriesFromDictionary:intermediateLookups];

    NSMutableDictionary *plist = [NSMutableDictionary dictionary];

    NSMutableDictionary *metadata = [NSMutableDictionary dictionary];
    [metadata setObject:[NSNumber numberWithInt:1] forKey:@"version"];

    [plist setObject:metadata forKey:@"metadata"];
    [plist setObject:_lookup forKey:@"filenames"];

    return [plist writeToFile:filePath atomically:YES];
}

- (NSMutableDictionary *)loadAndMergeIntermediateLookups
{
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    for (NSString *intermediateLookupPath in _intermediateLookupPaths)
    {
        NSDictionary *content = [NSDictionary dictionaryWithContentsOfFile:intermediateLookupPath];
        if (content)
        {
            [result addEntriesFromDictionary:content];
        }
    }
    return result;
}

- (void)addIntermediateLookupPath:(NSString *)filePath
{
    if (!filePath)
    {
        return;
    }

    [_intermediateLookupPaths addObject:filePath];
}

- (NSString *)description
{
    return [_lookup description];
}

@end