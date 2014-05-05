//
//  InspectorStringSimple.m
//  SpriteBuilder
//
//  Created by John Twigg on 2013-12-18.
//
//

#import "InspectorStringSimple.h"
#import "StringPropertySetter.h"
#import "AppDelegate.h"
#import "CocosScene.h"

@implementation InspectorStringSimple

- (void) setText:(NSString *)text
{
    [[AppDelegate appDelegate] saveUndoStateWillChangeProperty:propertyName];
    
    NSString* str = text;
    if (!str) str = @"";
    
    [self setPropertyForSelection:str];
}

- (NSString*) text
{
    return [StringPropertySetter stringForNode:selection andProp:propertyName];
}

- (void)controlTextDidChange:(NSNotification *)note
{
    NSTextField * changedField = [note object];
    NSString* text = [changedField stringValue];
    [self setText:text];
}

- (void) refresh
{
    [self willChangeValueForKey:@"text"];
    [self didChangeValueForKey:@"text"];
    
    [StringPropertySetter refreshStringProp:propertyName forNode:selection];
    [super refresh];    
}
@end
