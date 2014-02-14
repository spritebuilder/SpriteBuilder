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
    
    CCSizeType type = [PositionPropertySetter sizeTypeForNode:selection prop:propertyName];
    if (type.heightUnit == CCSizeUnitNormalized) height /= 100.0f;
    
	NSSize size = [PositionPropertySetter sizeForNode:selection prop:propertyName];
    size.height = height;
    [PositionPropertySetter setSize:size forNode:selection prop:propertyName];
    
    [self updateAffectedProperties];

}


@end
