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

    _lookup[src] = dst;
}

- (BOOL)writeToFileAtomically:(NSString *)filePath
{
    NSMutableDictionary *intermediateLookups = [self loadAndMergeIntermediateLookups];
    [_lookup addEntriesFromDictionary:intermediateLookups];

    NSMutableDictionary *plist = [NSMutableDictionary dictionary];

    NSMutableDictionary *metadata = [NSMutableDictionary dictionary];
    metadata[@"version"] = @1;

    plist[@"metadata"] = metadata;
    plist[@"filenames"] = _lookup;

    return [plist writeToFile:filePath atomically:YES];
}

- (BOOL)TEMPwriteMetadataToFileAtomically:(NSString *)filePath
{
    NSMutableDictionary *intermediateLookups = [self loadAndMergeIntermediateLookups];
    [_lookup addEntriesFromDictionary:intermediateLookups];
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    for(NSString *alias in _lookup){
        data[alias] = @{@"filename": _lookup[alias]};
    }
    
    NSDictionary *metadata = @{@"data": data};
    return [metadata writeToFile:filePath atomically:YES];
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