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

- (void) removeTemplate:(PropertyInspectorTemplate*) templ
{
    [templateLibrary removeTemplate:templ];
    [self updateTemplates];
    [collectionView setSelectionIndexes:[NSIndexSet indexSet]];
}

- (void) applyTemplate:(PropertyInspectorTemplate*) templ
{
    CCNode* node = [CocosBuilderAppDelegate appDelegate].selectedNode;
    if (!node) return;
    if (!templ.properties) return;
    
    [[CocosBuilderAppDelegate appDelegate] saveUndoStateWillChangeProperty:@"*template"];
    [templ applyToNode:node];
}

- (void) installDefaultTemplatesReplace:(BOOL)replace
{
    NSFileManager* fm = [NSFileManager defaultManager];
    NSString* templDir = [PropertyInspectorTemplateLibrary templateDirectory];
    
    // Check if templates are already installed
    BOOL templatesExist = [fm fileExistsAtPath:[templDir stringByAppendingPathComponent:@"templates.plist"]];
    if (templatesExist && !replace)
    {
        NSLog(@"Templates already installed.");
        return;
    }
    
    NSLog(@"Installing default templates.");
    
    // Remove old templates (if any)
    [fm removeItemAtPath:templDir error:NULL];
    
    // Unzip default templates
    NSString* zipFile = [[NSBundle mainBundle] pathForResource:@"defaultTemplates" ofType:@"zip"];
    
    NSTask* zipTask = [[NSTask alloc] init];
    [zipTask setCurrentDirectoryPath:[templDir stringByDeletingLastPathComponent]];
    [zipTask setLaunchPath:@"/usr/bin/unzip"];
    NSArray* args = [NSArray arrayWithObjects:zipFile, nil];
    [zipTask setArguments:args];
    [zipTask launch];
    [zipTask waitUntilExit];
    [zipTask release];
}

- (void) loadTemplateLibrary
{
    [templateLibrary loadLibrary];
}

@end
