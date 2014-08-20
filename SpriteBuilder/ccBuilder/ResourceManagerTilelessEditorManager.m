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
#import "CCBImageBrowserView.h"
#import "AppDelegate.h"
#import "ProjectSettings.h"
#import "RMDirectory.h"
#import "RMResource.h"
#import "ResourceTypes.h"

@implementation ResourceManagerTilelessEditorManager

- (id) initWithImageBrowser:(CCBImageBrowserView*)bw
{
    self = [super init];
    if (!self) return NULL;
    
    // Keep track of browser
    browserView = bw;
    browserView.dataSource = self;
    browserView.delegate = self;
    
    // Setup options
    NSColor* cBG = [NSColor colorWithCalibratedRed:0.93 green:0.93 blue:0.93 alpha:1];
    
    browserView.intercellSpacing = CGSizeMake(2, 2);
    browserView.cellSize = CGSizeMake(54, 54);
    [browserView setValue:cBG forKey:IKImageBrowserBackgroundColorKey];
    
    // Title font
    NSMutableDictionary* attr = [NSMutableDictionary dictionary];
    [attr setObject:[NSFont systemFontOfSize:10] forKey:NSFontAttributeName];
    [browserView setValue:attr forKey:IKImageBrowserCellsTitleAttributesKey];
    [browserView setValue:attr forKey:IKImageBrowserCellsHighlightedTitleAttributesKey];
    [browserView setValue:cBG forKey:IKImageBrowserSelectionColorKey];
    [browserView setValue:cBG forKey:IKImageBrowserCellsOutlineColorKey];
    
    // Register with resource manager
    [[ResourceManager sharedManager] addResourceObserver:self];
    
    imageResources = [[NSMutableArray alloc] init];
    imageGroups = [[NSMutableArray alloc] init];
    imageGroupsActive = [[NSMutableArray alloc] init];
    
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

- (NSDictionary *) imageBrowser:(IKImageBrowserView *) aBrowser groupAtIndex:(NSUInteger) index
{
    return [imageGroupsActive objectAtIndex:index];
}

- (NSUInteger) numberOfGroupsInImageBrowser:(IKImageBrowserView *) aBrowser
{
    return [imageGroupsActive count];
}

- (NSUInteger) imageBrowser:(IKImageBrowserView *) aBrowser writeItemsAtIndexes:(NSIndexSet *) itemIndexes toPasteboard:(NSPasteboard *)pasteboard
{
    [pasteboard clearContents];
    
    RMResource* item = [imageResources objectAtIndex:[itemIndexes firstIndex]];
    
    NSMutableArray* pbItems = [NSMutableArray array];
    [pbItems addObject:item];
    
    [pasteboard writeObjects:pbItems];
    
    // Deselect
    [browserView deselectAll];
    
    return 1;
}

#pragma mark Callback from ResourceMangager

- (void) resourceListUpdated
{
    ProjectSettings* settings = [AppDelegate appDelegate].projectSettings;
    
    [imageResources removeAllObjects];
    [imageGroups removeAllObjects];
    [imageGroupsActive removeAllObjects];
    
    if ([ResourceManager sharedManager].activeDirectories.count > 0)
    {
        NSDictionary* dirs = [ResourceManager sharedManager].directories;
        for (NSString* dirPath in dirs)
        {
            // Get info about the directory
            RMDirectory* dir = [dirs objectForKey:dirPath];
            
            NSString* relDirPath = [ResourceManagerUtil relativePathFromAbsolutePath:dir.dirPath];
            NSString* relDirPathName = [relDirPath lastPathComponent];
            if (!relDirPath || [relDirPath isEqualToString:@""])
            {
                relDirPathName = @"Resources";
                relDirPath = @"";
            }
            
            BOOL isActiveDir = ![[settings propertyForRelPath:relDirPath andKey:@"previewFolderHidden"] boolValue];
            
            
            int numImagesInDir = 0;
            int startFileIdx = [imageResources count];
            
            for (RMResource* res in dir.any)
            {
                if (res.type == kCCBResTypeImage ||
                    res.type == kCCBResTypeCCBFile)
                {
                    if (isActiveDir) [imageResources addObject:res];
                    numImagesInDir++;
                }
            }
            
            if (numImagesInDir > 0)
            {
                // Add a group
                NSMutableDictionary* group = [NSMutableDictionary dictionary];
                
                [group setObject:relDirPath forKey:@"relDirPath"];
                
                [group setObject:[NSValue valueWithRange:NSMakeRange(startFileIdx, numImagesInDir)] forKey:IKImageBrowserGroupRangeKey];
                [group setObject:relDirPathName forKey:IKImageBrowserGroupTitleKey];
                [group setObject:[NSNumber numberWithInt:IKGroupDisclosureStyle] forKey:IKImageBrowserGroupStyleKey];
                
                // Colors
                CGColorRef cBlack = CGColorCreateGenericRGB(0, 0, 0, 1);
                CGColorRef cGray = CGColorCreateGenericRGB(0.63, 0.63, 0.63, 1);
                
                // Create group header with background image
                CALayer *headerLayer = [CALayer layer];
                headerLayer.contentsScale = [[NSScreen mainScreen] backingScaleFactor];
                headerLayer.frame = CGRectMake(0, 0, 100, 16);
                headerLayer.contents = [NSImage imageNamed:@"header-bg2-crop.png"];
                
                // Text for header
                CATextLayer* textLayer = [CATextLayer layer];
                textLayer.contentsScale = [[NSScreen mainScreen] backingScaleFactor];
                textLayer.bounds = CGRectMake(0, 0, 250, 20);
                textLayer.frame = CGRectMake(3, -5, 250, 20);
                textLayer.string = relDirPathName;
                textLayer.font = (__bridge CFTypeRef)([NSFont systemFontOfSize:11]);
                textLayer.fontSize = 11;
                textLayer.foregroundColor = cBlack;
                
                [headerLayer addSublayer:textLayer];
                
                // Footer layer (with just a line)
                CALayer* footerLayer = [CALayer layer];
                footerLayer.backgroundColor = cGray;
                footerLayer.frame = CGRectMake(0, 0, 100, 5);
                
                // Add header and footer
                [group setObject:headerLayer forKey:IKImageBrowserGroupHeaderLayer];
                [group setObject:footerLayer forKey:IKImageBrowserGroupFooterLayer];
                
                // Remember this image group
                [imageGroups addObject:group];
                
                if (![[settings propertyForRelPath:relDirPath andKey:@"previewFolderHidden"] boolValue])
                {
                    [imageGroupsActive addObject:group];
                }
                
                // Release objects
                CFRelease(cBlack);
                CFRelease(cGray);
            }
        }
    }
    
    [browserView reloadData];
}

- (void) imageBrowser:(IKImageBrowserView *) aBrowser cellWasDoubleClickedAtIndex:(NSUInteger) index
{
    RMResource* res = [imageResources objectAtIndex:index];
    if (res.type == kCCBResTypeCCBFile)
    {
        [[AppDelegate appDelegate] openFile:res.filePath];
        return;
    }
    [super imageBrowser:aBrowser cellWasDoubleClickedAtIndex:index];
}

#pragma mark Table View data source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [imageGroups count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if ([aTableColumn.identifier isEqualToString:@"enable"])
    {
        ProjectSettings* settings = [AppDelegate appDelegate].projectSettings;
        NSString* relDirPath = [[imageGroups objectAtIndex:rowIndex] objectForKey:@"relDirPath"];
        
        BOOL previewFolderHidden = [[settings propertyForRelPath:relDirPath andKey:@"previewFolderHidden"] boolValue];
        
        return [NSNumber numberWithBool:!previewFolderHidden];
    }
    else if ([aTableColumn.identifier isEqualToString:@"dir"])
    {
        return [[imageGroups objectAtIndex:rowIndex] objectForKey:IKImageBrowserGroupTitleKey];
    }
    return NULL;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)value forTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
    if ([column.identifier isEqualToString:@"enable"])
    {
        // Update the value
        ProjectSettings* settings = [AppDelegate appDelegate].projectSettings;
        NSString* relDirPath = [[imageGroups objectAtIndex:row] objectForKey:@"relDirPath"];
        [settings setProperty:[NSNumber numberWithBool:![value boolValue]] forRelPath:relDirPath andKey:@"previewFolderHidden"];
        
        // Deselect the table view to prevent toggle to fire twice
        [tableView deselectAll:self];
        
        // Reload the image view
        [self resourceListUpdated];
    }
}

- (void) tableViewSelectionDidChange:(NSNotification *)notification
{
    NSTableView* tableView = notification.object;
    
    if (tableView.selectedRow != -1)
    {
        // Toggle checkbox
        ProjectSettings* settings = [AppDelegate appDelegate].projectSettings;
        NSString* relDirPath = [[imageGroups objectAtIndex:tableView.selectedRow] objectForKey:@"relDirPath"];
        
        BOOL previewFolderHidden = [[settings propertyForRelPath:relDirPath andKey:@"previewFolderHidden"] boolValue];
        [settings setProperty:[NSNumber numberWithBool:!previewFolderHidden] forRelPath:relDirPath andKey:@"previewFolderHidden"];
        
        [tableView deselectAll:self];
        [tableView reloadData];
        [self resourceListUpdated];
    }
}

#pragma mark Split View constraints

- (CGFloat) splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex
{
    if (proposedMinimumPosition < 160) return 160;
    else return proposedMinimumPosition;
}

- (CGFloat) splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMaximumPosition ofSubviewAt:(NSInteger)dividerIndex
{
    float max = splitView.frame.size.height - 100;
    if (proposedMaximumPosition > max) return max;
    else return proposedMaximumPosition;
}

#pragma mark Dealloc


@end
