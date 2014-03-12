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

#import "InspectorFloatScale.h"
#import "PositionPropertySetter.h"
#import "CCBGlobals.h"
#import "AppDelegate.h"
#import "ProjectSettings.h"

@implementation InspectorFloatScale

- (void) willBeAdded
{
    [_scaleType setEnabled:[AppDelegate appDelegate].projectSettings.engine == CCBTargetEngineCocos2dx forSegment:1];
    for(int i=0;i<2;++i)
        [_scaleType setSelected:(self.type&(1<<i)) forSegment:i];
}

- (void) setF:(float)f
{
    [[AppDelegate appDelegate] saveUndoStateWillChangeProperty:propertyName];
    
    [PositionPropertySetter setFloatScale:f type:[PositionPropertySetter floatScaleTypeForNode:selection prop:propertyName] forNode:selection prop:propertyName];
    
    [self updateAffectedProperties];
}

- (float) f
{
    return [PositionPropertySetter floatScaleForNode:selection prop:propertyName];
}

- (int) type
{
    return [PositionPropertySetter floatScaleTypeForNode:selection prop:propertyName];
}


- (IBAction)touch:(id)sender {
    [[AppDelegate appDelegate] saveUndoStateWillChangeProperty:propertyName];
    int type = 0;
    for(int i=0;i<2;++i)
        if([_scaleType isSelectedForSegment:i])
            type|=1<<i;
    [self setType:type];
}

- (void) setType:(int)type
{
    [[AppDelegate appDelegate] saveUndoStateWillChangeProperty:propertyName];
    
    [PositionPropertySetter setFloatScale:[PositionPropertySetter floatScaleForNode:selection prop:propertyName] type: type forNode:selection prop:propertyName];
    
    [self updateAffectedProperties];
}

- (void) refresh
{
    [self willChangeValueForKey:@"f"];
    [self didChangeValueForKey:@"f"];
}

@end
