//
//  NodePhysicsBody.h
//  SpriteBuilder
//
//  Created by Viktor on 9/30/13.
//
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

enum
{
    kCCBPhysicsBodyShapePolygon,
    kCCBPhysicsBodyShapeCircle,
};

@interface NodePhysicsBody : NSObject

// Shape
@property (nonatomic,assign) int bodyShape;
@property (nonatomic,assign) float cornerRadius;
@property (nonatomic,retain) NSArray* points;

// Basic physic props
@property (nonatomic,assign) BOOL dynamic;
@property (nonatomic,assign) BOOL affectedByGravity;
@property (nonatomic,assign) BOOL allowsRotation;

@property (nonatomic,assign) float density;
@property (nonatomic,assign) float friction;
@property (nonatomic,assign) float elasticity;

- (id) initWithNode:(CCNode*) node;

@end
