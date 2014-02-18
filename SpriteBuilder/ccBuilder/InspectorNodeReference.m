//
//  InspectorNodeReference.m
//  SpriteBuilder
//
//  Created by John Twigg on 2/13/14.
//
//

#import "InspectorNodeReference.h"
#import "PositionPropertySetter.h"
#import "CCBGlobals.h"
#import "AppDelegate.h"

@implementation InspectorNodeReference
@dynamic reference;

-(void)setReference:(CCNode *)reference
{
    [[AppDelegate appDelegate] saveUndoStateWillChangeProperty:propertyName];
    
    [selection setValue:reference forKey:propertyName];
    
    [self updateAffectedProperties];
}

-(CCNode*)reference
{
    return [selection valueForKey:propertyName];
}


-(NSString*)nodeName
{
    return self.reference.displayName;
}


- (void) refresh
{
    [self willChangeValueForKey:@"reference"];
    [self didChangeValueForKey:@"reference"];
    
    [self willChangeValueForKey:@"nodeName"];
    [self didChangeValueForKey:@"nodeName"];
    
}

- (IBAction)handleDeleteNode:(id)sender
{
    self.reference = nil;
}

- (IBAction)handleGotoNode:(id)sender
{
    
}
@end
