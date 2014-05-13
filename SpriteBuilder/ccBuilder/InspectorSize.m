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

#import "InspectorSize.h"
#import "PositionPropertySetter.h"
#import "CCBGlobals.h"
#import "AppDelegate.h"

@implementation InspectorSize

- (void) setWidth:(float)width
{
    [[AppDelegate appDelegate] saveUndoStateWillChangeProperty:propertyName];
    
    CCSizeType type = [PositionPropertySetter sizeTypeForNode:selection prop:propertyName];
    if (type.widthUnit == CCSizeUnitNormalized) width /= 100.0f;
    
    NSSize size = [PositionPropertySetter sizeForNode:selection prop:propertyName];
    size.width = width;
    [PositionPropertySetter setSize:size forNode:selection prop:propertyName];
    
    [self updateAffectedProperties];
}

- (float) width
{
    CCSizeType type = [PositionPropertySetter sizeTypeForNode:selection prop:propertyName];
    float width = [PositionPropertySetter sizeForNode:selection prop:propertyName].width;
    
    if (type.widthUnit == CCSizeUnitNormalized) width *= 100.0f;
    
    return width;
}

- (void) setHeight:(float)height
{
    [[AppDelegate appDelegate] saveUndoStateWillChangeProperty:propertyName];
    
    CCSizeType type = [PositionPropertySetter sizeTypeForNode:selection prop:propertyName];
    if (type.heightUnit == CCSizeUnitNormalized) height /= 100.0f;
    
	NSSize size = [PositionPropertySetter sizeForNode:selection prop:propertyName];
    size.height = height;
    [PositionPropertySetter setSize:size forNode:selection prop:propertyName];
    
    [self updateAffectedProperties];
}

- (float) height
{
    CCSizeType type = [PositionPropertySetter sizeTypeForNode:selection prop:propertyName];
    float height = [PositionPropertySetter sizeForNode:selection prop:propertyName].height;
    
    if (type.heightUnit == CCSizeUnitNormalized) height *= 100.0f;
    
    return height;
}

- (void) setWidthUnit:(int)widthUnit
{
    CCSizeType type = [PositionPropertySetter sizeTypeForNode:selection prop:propertyName];
    type.widthUnit = widthUnit;
    [self setType:type];
}

- (int) widthUnit
{
    CCSizeType type = [PositionPropertySetter sizeTypeForNode:selection prop:propertyName];
    return type.widthUnit;
}

- (void) setHeightUnit:(int)heightUnit
{
    CCSizeType type = [PositionPropertySetter sizeTypeForNode:selection prop:propertyName];
    type.heightUnit = heightUnit;
    [self setType:type];
}

- (int) heightUnit
{
    CCSizeType type = [PositionPropertySetter sizeTypeForNode:selection prop:propertyName];
    return type.heightUnit;
}

- (void) setType:(CCSizeType)type
{
    [[AppDelegate appDelegate] saveUndoStateWillChangeProperty:propertyName];
    
    [PositionPropertySetter setSizeType:type forNode:selection prop:propertyName];
    
    [self refresh];
    
    [self updateAffectedProperties];
}

- (void) refresh
{
    [self willChangeValueForKey:@"width"];
    [self didChangeValueForKey:@"width"];
    
    [self willChangeValueForKey:@"height"];
    [self didChangeValueForKey:@"height"];
    
    [self willChangeValueForKey:@"widthUnit"];
    [self didChangeValueForKey:@"widthUnit"];
    
    [self willChangeValueForKey:@"heightUnit"];
    [self didChangeValueForKey:@"heightUnit"];
    [super refresh];    
}

@end
