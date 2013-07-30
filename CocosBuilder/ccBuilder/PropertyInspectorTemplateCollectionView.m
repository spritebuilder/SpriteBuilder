//
//  PropertyInspectorTemplateCollectionView.m
//  CocosBuilder
//
//  Created by Viktor on 7/29/13.
//
//

#import "PropertyInspectorTemplateCollectionView.h"
#import "CCBColorView.h"
#import "PropertyInspectorTemplate.h"

@implementation PropertyInspectorTemplateCollectionView

- (NSCollectionViewItem*) newItemForRepresentedObject:(id)object
{
    PropertyInspectorTemplate* templ = object;
    
    NSCollectionViewItem* item = [super newItemForRepresentedObject:object];
    NSView* view = item.view;
    
    NSTextField* lblName = [view viewWithTag:2];
    NSImageView* imgPreview = [view viewWithTag:1];
    
    lblName.stringValue = templ.name;
    imgPreview.image = templ.image;
    
    // Create background view
    CCBColorView* bg = [[[CCBColorView alloc] initWithFrame:NSMakeRect(2, view.bounds.size.height - view.bounds.size.width + 2, view.bounds.size.width - 4, view.bounds.size.width - 4)] autorelease];
    bg.backgroundColor = templ.color;
    bg.radius = 5;
    
    [view addSubview:bg positioned:NSWindowBelow relativeTo:NULL];
    
    return item;
}

- (NSFocusRingType) focusRingType
{
    return NSFocusRingTypeNone;
}

- (void) setSelectionIndexes:(NSIndexSet *)indexes
{
    // Reset all items
    for (int i = 0; i < [self content].count; i++)
    {
        NSCollectionViewItem* item = [self itemAtIndex:i];
        
        NSView* view = item.view;
        CCBColorView* bg = [[view subviews] objectAtIndex:0];
        bg.borderColor = NULL;
    }
    
    // Select the current item
    if (indexes.count)
    {
        NSCollectionViewItem* item = [self itemAtIndex:[indexes firstIndex]];
        
        NSView* view = item.view;
        CCBColorView* bg = [[view subviews] objectAtIndex:0];
        
        bg.borderColor = [NSColor colorWithCalibratedRed:0.47 green:0.75 blue:1 alpha:1];
    }
    
    [super setSelectionIndexes:indexes];
}

@end
