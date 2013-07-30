//
//  PropertyInspectorHandler.m
//  CocosBuilder
//
//  Created by Viktor on 7/29/13.
//
//

#import "PropertyInspectorHandler.h"

// TODO: Move more of the property inspector code over here!

@implementation PropertyInspectorHandler

- (void) awakeFromNib
{
    [collectionView setContent:[NSArray arrayWithObjects:@"A", @"B", @"C", nil]];
}

- (void) updateTemplates
{}

- (IBAction) addTemplate:(id) sender
{
    NSLog(@"addTemplate:");
}

- (IBAction) toggleShowDefaultTemplates:(id)sender
{
    NSLog(@"toggleShowDefaultTemplates:");
}

@end
