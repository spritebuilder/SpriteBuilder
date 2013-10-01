//
//  PhysicsHandler.h
//  SpriteBuilder
//
//  Created by Viktor on 9/30/13.
//
//

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
@property (nonatomic,readonly) NodePhysicsBody* selectedNodePhysicsBody;

- (void) selectionChanged;

- (void) updatePhysicsEditor:(CCNode*) editorView;

- (BOOL) mouseDown:(CGPoint)pos event:(NSEvent*)event;
- (BOOL) mouseDragged:(CGPoint)pos event:(NSEvent*)event;
- (BOOL) mouseUp:(CGPoint)pos event:(NSEvent*)event;

@end
