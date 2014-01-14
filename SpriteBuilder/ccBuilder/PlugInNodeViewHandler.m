//
//  PlugInNodeViewHandler.m
//  CocosBuilder
//
//  Created by Viktor on 7/26/13.
//
//

#import "PlugInNodeViewHandler.h"
#import "PlugInManager.h"
#import "PlugInNode.h"

@implementation PlugInNodeViewHandler

- (id) initWithCollectionView:(NSCollectionView*)cv
{
    self = [super init];
    if (!self) return NULL;
    
    PlugInManager* pim = [PlugInManager sharedManager];
    
    plugIns = [[NSMutableArray alloc] init];
    
    NSArray* nodeNames = pim.plugInsNodeNames;
    for (NSString* nodeName in nodeNames)
    {
        [plugIns addObject:[pim plugInNodeNamed:nodeName]];
    }
    
    [plugIns sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"ordering" ascending:YES]]];
    
    collectionView = cv;
    [collectionView setContent:plugIns];
    collectionView.delegate = self;
    
    return self;
}

- (BOOL)collectionView:(NSCollectionView *)collectionView writeItemsAtIndexes:(NSIndexSet *)indexes toPasteboard:(NSPasteboard *)pasteboard
{
    [pasteboard clearContents];
    
    PlugInNode* plugIn = [plugIns objectAtIndex:[indexes firstIndex]];
    
    NSMutableArray* pbItems = [NSMutableArray array];
    [pbItems addObject:plugIn];
    
    [pasteboard writeObjects:pbItems];
    
    return YES;
}

- (NSImage *)collectionView:(NSCollectionView *)collectionView draggingImageForItemsAtIndexes:(NSIndexSet *)indexes withEvent:(NSEvent *)event offset:(NSPointPointer)dragImageOffset
{
    PlugInNode* plugIn = [plugIns objectAtIndex:[indexes firstIndex]];
    return plugIn.icon;
}


@end
