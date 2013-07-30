//
//  PropertyInspectorHandler.m
//  CocosBuilder
//
//  Created by Viktor on 7/29/13.
//
//

#import "PropertyInspectorHandler.h"
#import "CocosBuilderAppDelegate.h"
#import "CCNode+NodeInfo.h"
#import "PlugInNode.h"
#import "PropertyInspectorTemplate.h"

// TODO: Move more of the property inspector code over here!

@implementation PropertyInspectorHandler

/*
- (void) awakeFromNib
{
    [collectionView setContent:[NSArray arrayWithObjects:@"A", @"B", @"C", nil]];
}*/

- (void) updateTemplates
{
    CCNode* node = [CocosBuilderAppDelegate appDelegate].selectedNode;
    
    if (!node) return;
    PlugInNode* plugIn = node.plugIn;
    NSString* plugInName = plugIn.nodeClassName;
    
    NSArray* templates = [templateLibrary templatesForNodeType:plugInName];
    
    [collectionView setContent:templates];
}

- (IBAction) addTemplate:(id) sender
{
    CCNode* node = [CocosBuilderAppDelegate appDelegate].selectedNode;
    if (!node) return;
    
    if (!newTemplateName.stringValue || [newTemplateName.stringValue isEqualToString:@""]) return;
    
    PropertyInspectorTemplate* templ = [[[PropertyInspectorTemplate alloc] initWithNode:node name:newTemplateName.stringValue bgColor:newTemplateBgColor.color] autorelease];
    
    [templateLibrary addTemplate:templ];
    
    [newTemplateName setStringValue:@""];
    [self updateTemplates];
    
    // Resign focus for text field
    [[newTemplateName window] makeFirstResponder:[newTemplateName window]];
}

- (IBAction) toggleShowDefaultTemplates:(id)sender
{
    NSLog(@"toggleShowDefaultTemplates:");
}

@end
