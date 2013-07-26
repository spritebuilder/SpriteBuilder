//
//  PlugInNodeCollectionView.m
//  CocosBuilder
//
//  Created by Viktor on 7/26/13.
//
//

#import "PlugInNodeCollectionView.h"
#import "PlugInNode.h"

@implementation PlugInNodeCollectionView

- (NSCollectionViewItem*) newItemForRepresentedObject:(id)object
{
    PlugInNode* pi = object;
    
    NSCollectionViewItem* item = [super newItemForRepresentedObject:object];
    NSLog(@"item.view: %@", item.view);
    
    NSView* view = item.view;
    
    NSTextField* lblName = [view viewWithTag:1];
    NSTextField* lblDescr = [view viewWithTag:2];
    NSImageView* imgIcon = [view viewWithTag:3];
    
    lblName.stringValue = pi.nodeClassName;
    //lblDescr.stringValue = @"Custom description";
    imgIcon.image = pi.icon;
    
    return item;
}

@end
