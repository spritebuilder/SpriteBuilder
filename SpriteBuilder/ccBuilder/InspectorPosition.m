/*
 * CocosBuilder: http://www.cocosbuilder.com
 *
 * Copyright (c) 2012 Zynga Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "InspectorPosition.h"
#import "PositionPropertySetter.h"
#import "CCBGlobals.h"
#import "AppDelegate.h"
#import "CCNode+NodeInfo.h"
#import "SequencerKeyframe.h"

@implementation InspectorPosition

- (void) setPosX:(float)posX
{
    [[AppDelegate appDelegate] saveUndoStateWillChangeProperty:propertyName];
    
    CCPositionType type = [PositionPropertySetter positionTypeForNode:selection prop:propertyName];
    if (type.xUnit == CCPositionUnitNormalized) posX /= 100.0f;
    
	NSPoint pt = [PositionPropertySetter positionForNode:selection prop:propertyName];
    pt.x = posX;
    [PositionPropertySetter setPosition:pt type:[PositionPropertySetter positionTypeForNode:selection prop:propertyName] forNode:selection prop:propertyName];
    
    NSArray* animValue = [NSArray arrayWithObjects:
                          [NSNumber numberWithFloat:pt.x],
                          [NSNumber numberWithFloat:pt.y],
                          NULL];
    [self updateAnimateablePropertyValue:animValue];
    
    [self updateAffectedProperties];
}

- (float) posX
{
    float posX = [[selection valueForKey:propertyName] pointValue].x;
    CCPositionType type = [PositionPropertySetter positionTypeForNode:selection prop:propertyName];
    if (type.xUnit == CCPositionUnitNormalized) posX *= 100.0f;
    return posX;
}

- (void) setPosY:(float)posY
{
    [[AppDelegate appDelegate] saveUndoStateWillChangeProperty:propertyName];
    
    CCPositionType type = [PositionPropertySetter positionTypeForNode:selection prop:propertyName];
    if (type.yUnit == CCPositionUnitNormalized) posY /= 100.0f;
    
    NSPoint pt = [PositionPropertySetter positionForNode:selection prop:propertyName];
    pt.y = posY;
    [PositionPropertySetter setPosition:pt type:[PositionPropertySetter positionTypeForNode:selection prop:propertyName] forNode:selection prop:propertyName];
    
    NSArray* animValue = [NSArray arrayWithObjects:
                          [NSNumber numberWithFloat:pt.x],
                          [NSNumber numberWithFloat:pt.y],
                          NULL];
    [self updateAnimateablePropertyValue:animValue];
    
    [self updateAffectedProperties];
}

- (float) posY
{
    float posY = [[selection valueForKey:propertyName] pointValue].y;
    CCPositionType type = [PositionPropertySetter positionTypeForNode:selection prop:propertyName];
    if (type.yUnit == CCPositionUnitNormalized) posY *= 100.0f;
    return posY;
}

- (id) convertAnimatableValue:(id)value fromType:(CCPositionType)fromType toType:(CCPositionType)toType
{
    NSPoint relPos = NSZeroPoint;
    relPos.x = [[value objectAtIndex:0] floatValue];
    relPos.y = [[value objectAtIndex:1] floatValue];
    
    relPos = [PositionPropertySetter convertPosition:relPos fromType:fromType toType:toType forNode:selection];
    
    return [NSArray arrayWithObjects:
                              [NSNumber numberWithFloat:relPos.x],
                              [NSNumber numberWithFloat:relPos.y],
                              NULL];
}

- (void) setPositionType:(CCPositionType)positionType
{
    [[AppDelegate appDelegate] saveUndoStateWillChangeProperty:propertyName];
    
    CCPositionType oldPositionType = [PositionPropertySetter positionTypeForNode:selection prop:propertyName];
    
    // Update keyframes
    NSArray* keyframes = [selection keyframesForProperty:propertyName];
    for (SequencerKeyframe* keyframe in keyframes)
    {
        keyframe.value = [self convertAnimatableValue:keyframe.value fromType:oldPositionType toType:positionType];
    }
    
    // Update base value
    id baseValue = [selection baseValueForProperty:propertyName];
    if (baseValue)
    {
        baseValue = [self convertAnimatableValue:baseValue fromType:oldPositionType toType:positionType];
        [selection setBaseValue:baseValue forProperty:propertyName];
    }
    
    [PositionPropertySetter setPositionType:positionType oldPositionType:oldPositionType forNode:selection prop:propertyName];
    [self refresh];
    
    [self updateAffectedProperties];
}

- (void) setPositionUnitX:(int)positionUnitX
{
    CCPositionType type = [PositionPropertySetter positionTypeForNode:selection prop:propertyName];
    type.xUnit = positionUnitX;
    [self setPositionType:type];
}

- (void) setPositionUnitY:(int)positionUnitY
{
    CCPositionType type = [PositionPropertySetter positionTypeForNode:selection prop:propertyName];
    type.yUnit = positionUnitY;
    [self setPositionType:type];
}

- (void) setReferenceCorner:(int)referenceCorner
{
    CCPositionType type = [PositionPropertySetter positionTypeForNode:selection prop:propertyName];
    type.corner = referenceCorner;
    [self setPositionType:type];
}

- (int) positionUnitX
{
    CCPositionType type = [PositionPropertySetter positionTypeForNode:selection prop:propertyName];
    return type.xUnit;
}

- (int) positionUnitY
{
    CCPositionType type = [PositionPropertySetter positionTypeForNode:selection prop:propertyName];
    return type.yUnit;
}

- (int) referenceCorner
{
    CCPositionType type = [PositionPropertySetter positionTypeForNode:selection prop:propertyName];
    return type.corner;
}

- (void) refresh
{
    [self willChangeValueForKey:@"posX"];
    [self didChangeValueForKey:@"posX"];
    
    [self willChangeValueForKey:@"posY"];
    [self didChangeValueForKey:@"posY"];
    
    [self willChangeValueForKey:@"positionUnitX"];
    [self didChangeValueForKey:@"positionUnitX"];
    
    [self willChangeValueForKey:@"positionUnitY"];
    [self didChangeValueForKey:@"positionUnitY"];
    
    [self willChangeValueForKey:@"referenceCorner"];
    [self didChangeValueForKey:@"referenceCorner"];
    [super refresh];    
}

@end
