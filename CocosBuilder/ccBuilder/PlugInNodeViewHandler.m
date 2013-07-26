//
//  PlugInNodeViewHandler.m
//  CocosBuilder
//
//  Created by Viktor on 7/26/13.
//
//

#import "PlugInNodeViewHandler.h"
#import "PlugInManager.h"

@implementation PlugInNodeViewHandler

- (id) initWithCollectionView:(NSCollectionView*)cv
{
    self = [super init];
    if (!self) return NULL;
    
    PlugInManager* pim = [PlugInManager sharedManager];
    
    NSMutableArray* plugIns = [NSMutableArray array];
    NSArray* nodeNames = pim.plugInsNodeNames;
    for (NSString* nodeName in nodeNames)
    {
        [plugIns addObject:[pim plugInNodeNamed:nodeName]];
    }
    
    collectionView = cv;
    [collectionView setContent:plugIns];
    
    return self;
}

@end
