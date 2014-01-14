/*
 * CocosBuilder: http://www.cocosbuilder.com
 *
 * Copyright (c) 2013 Apportable Inc
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

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@class NodePhysicsBody;

@interface PhysicsHandler : NSObject
{
    CGPoint _mouseDownPos;
    int _mouseDownInHandle;
    CGPoint _handleStartPos;
}

@property (nonatomic,assign) BOOL editingPhysicsBody;
@property (nonatomic,assign) BOOL selectedNodePhysicsEnabled;
@property (nonatomic,strong) NodePhysicsBody* selectedNodePhysicsBody;

- (void) willChangeSelection;
- (void) didChangeSelection;

- (void) updatePhysicsEditor:(CCNode*) editorView;

- (BOOL) mouseDown:(CGPoint)pos event:(NSEvent*)event;
- (BOOL) mouseDragged:(CGPoint)pos event:(NSEvent*)event;
- (BOOL) mouseUp:(CGPoint)pos event:(NSEvent*)event;

@end
