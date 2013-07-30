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
    
    NSString* newName = newTemplateName.stringValue;
    
    // Make sure that the name is a valid file name
    newName = [newName stringByReplacingOccurrencesOfString:@"/" withString:@""];
    newName = [newName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (!newName || [newName isEqualToString:@""]) return;
    
    // Make sure it's a unique name
    if ([templateLibrary hasTemplateForNodeType:node.plugIn.nodeClassName andName:newName])
    {
        [[CocosBuilderAppDelegate appDelegate] modalDialogTitle:@"Failed to Create Template" message:@"You need to specify a unique name. Please try again."];
        return;
    }
    
    PropertyInspectorTemplate* templ = [[[PropertyInspectorTemplate alloc] initWithNode:node name:newName bgColor:newTemplateBgColor.color] autorelease];
    
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
