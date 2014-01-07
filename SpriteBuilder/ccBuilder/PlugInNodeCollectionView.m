//
//  PlugInNodeCollectionView.m
//  CocosBuilder
//
//  Created by Viktor on 7/26/13.
//
//

#import "PlugInNodeCollectionView.h"
#import "PlugInNode.h"
#import "CCBColorView.h"

@implementation PlugInNodeCollectionView

- (NSCollectionViewItem*) newItemForRepresentedObject:(id)object
{
    PlugInNode* pi = object;
    
    NSCollectionViewItem* item = [super newItemForRepresentedObject:object];
    NSView* view = item.view;
    
    NSTextField* lblName = [view viewWithTag:1];
    NSTextField* lblDescr = [view viewWithTag:2];
    NSImageView* imgIcon = [view viewWithTag:3];
    
    lblName.stringValue = pi.displayName;
    lblDescr.stringValue = pi.descr;
    imgIcon.image = pi.icon;
    
    // Create background view
    CCBColorView* bg = [[CCBColorView alloc] initWithFrame:NSMakeRect(2, 1, view.bounds.size.width - 5, view.bounds.size.height - 2)];
    bg.backgroundColor = [NSColor colorWithCalibratedRed:0.97 green:0.97 blue:0.97 alpha:1];
    bg.radius = 5;
    [view addSubview:bg positioned:NSWindowBelow relativeTo:NULL];
    
    return item;
}

- (NSFocusRingType) focusRingType
{
    return NSFocusRingTypeNone;
}

@end
