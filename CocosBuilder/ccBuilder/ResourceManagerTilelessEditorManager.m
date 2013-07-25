//
//  ResourceManagerTilelessEditorManager.m
//  CocosBuilder
//
//  Created by Viktor on 7/24/13.
//
//

#import "ResourceManagerTilelessEditorManager.h"
#import "ResourceManager.h"
#import "ResourceManagerUtil.h"

@implementation ResourceManagerTilelessEditorManager

- (id) initWithImageBrowser:(IKImageBrowserView*)bw
{
    self = [super init];
    if (!self) return NULL;
    
    // Keep track of browser
    browserView = bw;
    browserView.dataSource = self;
    
    // Setup options
    browserView.intercellSpacing = CGSizeMake(2, 2);
    browserView.cellSize = CGSizeMake(54, 54);
    [browserView setValue:[NSColor colorWithCalibratedRed:0.93 green:0.93 blue:0.93 alpha:1] forKey:IKImageBrowserBackgroundColorKey];
    
    // Title font
    NSMutableDictionary* attr = [NSMutableDictionary dictionary];
    [attr setObject:[NSFont systemFontOfSize:10] forKey:NSFontAttributeName];
    [browserView setValue:attr forKey:IKImageBrowserCellsTitleAttributesKey];
    
    // Register with resource manager
    [[ResourceManager sharedManager] addResourceObserver:self];
    
    imageResources = [[NSMutableArray alloc] init];
    
    return self;
}

#pragma mark Image Browser Data Provier

- (id) imageBrowser:(IKImageBrowserView *) aBrowser itemAtIndex:(NSUInteger)index
{
    return [imageResources objectAtIndex:index];
}

- (NSUInteger) numberOfItemsInImageBrowser:(IKImageBrowserView *) aBrowser
{
    return [imageResources count];
}

#pragma mark Callback from ResourceMangager

- (void) resourceListUpdated
{
    [imageResources removeAllObjects];
    
    NSDictionary* dirs = [ResourceManager sharedManager].directories;
    for (NSString* dirPath in dirs)
    {
        RMDirectory* dir = [dirs objectForKey:dirPath];
        
        for (RMResource* res in dir.images)
        {
            if (res.type == kCCBResTypeImage)
            {
                [imageResources addObject:res];
            }
        }
    }
    
    [browserView reloadData];
}

#pragma mark Dealloc

- (void) dealloc
{
    [imageResources release];
    [super dealloc];
}

@end
