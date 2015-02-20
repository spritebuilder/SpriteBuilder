#import "CCBDocumentManipulator.h"
#import "CCBDictionaryKeys.h"

@interface CCBDocumentManipulator ()

@property (nonatomic, strong, readwrite) NSMutableDictionary *document;

@end

@implementation CCBDocumentManipulator

#pragma mark - Initialization


- (instancetype)initWithDocument:(NSMutableDictionary *)document
{
    NSAssert(document != nil, @"nodeGraph must not be nil");

    self = [super init];

    if (self)
    {
        self.document = document;
    }

    return self;
}

- (void)processAllProperties:(PropertyReplacerBlock)propertyReplacerBlock
{
    if (!_document[CCB_DICTIONARY_KEY_NODEGRAPH])
    {
        return;
    }

    [self traverseChildrenAndMigrate:@[_document[CCB_DICTIONARY_KEY_NODEGRAPH]] propertyReplacerBlock:propertyReplacerBlock];
}

- (void)traverseChildrenAndMigrate:(NSArray *)children propertyReplacerBlock:(PropertyReplacerBlock)propertyReplacerBlock
{
    for (NSMutableDictionary *child in children)
    {
        NSMutableArray *nodeGraphProps = child[CCB_DICTIONARY_KEY_PROPERTIES];

        for (NSUInteger i = 0; i < nodeGraphProps.count; ++i)
        {
            nodeGraphProps[i] = [propertyReplacerBlock(nodeGraphProps[i], child) mutableCopy];
        }

        if ([child[CCB_DICTIONARY_KEY_CHILDREN] isKindOfClass:[NSArray class]])
        {
            [self traverseChildrenAndMigrate:child[CCB_DICTIONARY_KEY_CHILDREN] propertyReplacerBlock:propertyReplacerBlock];
        }
    }
}

@end