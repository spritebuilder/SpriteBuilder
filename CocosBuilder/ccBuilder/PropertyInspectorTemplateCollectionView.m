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
    CCBColorView* bg = [[[CCBColorView alloc] initWithFrame:NSMakeRect(2, view.bounds.size.height - view.bounds.size.width, view.bounds.size.width - 5, view.bounds.size.width - 2)] autorelease];
    bg.backgroundColor = templ.color;//[NSColor colorWithCalibratedRed:0.97 green:0.97 blue:0.97 alpha:1];
    bg.radius = 5;
    [view addSubview:bg positioned:NSWindowBelow relativeTo:NULL];
    
    return item;
}

- (NSFocusRingType) focusRingType
{
    return NSFocusRingTypeNone;
}

@end
