//
//  CCBSpriteKitCompatibility.h
//  SpriteKitReader-Experimental
//
//  Created by Steffen Itterheim on 09/01/14.
//  Copyright (c) 2014 Steffen Itterheim. All rights reserved.
//

// TODO: enclose in #ifdef COMPILING_FOR_SPRITEKIT

#define CCB_SPRITEKIT_READER

#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
#define __CC_PLATFORM_IOS 1
#elif defined(__MAC_OS_X_VERSION_MAX_ALLOWED)
#define __CC_PLATFORM_MAC 1
#endif

#import <SpriteKit/SpriteKit.h>
#import "CCFileUtils.h"
#import "CCBSpriteKitDummy.h"
#import "CGPointExtension.h"

typedef NS_ENUM(unsigned char, CCPositionUnit)
{
    CCPositionUnitPoints,
    CCPositionUnitUIPoints,
    CCPositionUnitNormalized,
};

typedef NS_ENUM(unsigned char, CCSizeUnit)
{
    CCSizeUnitPoints,
    CCSizeUnitUIPoints,
    CCSizeUnitNormalized,
    CCSizeUnitInsetPoints,
    CCSizeUnitInsetUIPoints,
};

typedef NS_ENUM(unsigned char, CCPositionReferenceCorner)
{
    CCPositionReferenceCornerBottomLeft,
    CCPositionReferenceCornerTopLeft,
    CCPositionReferenceCornerTopRight,
    CCPositionReferenceCornerBottomRight,
};

typedef struct _CCPositionType
{
    CCPositionUnit xUnit;
    CCPositionUnit yUnit;
    CCPositionReferenceCorner corner;
} CCPositionType;

typedef struct _CCSizeType
{
    CCSizeUnit widthUnit;
    CCSizeUnit heightUnit;
} CCSizeType;

static inline CCPositionType CCPositionTypeMake(CCPositionUnit xUnit, CCPositionUnit yUnit, CCPositionReferenceCorner corner)
{
    CCPositionType pt;
    pt.xUnit = xUnit;
    pt.yUnit = yUnit;
    pt.corner = corner;
    return pt;
}

static inline CCSizeType CCSizeTypeMake(CCSizeUnit widthUnit, CCSizeUnit heightUnit)
{
    CCSizeType cst;
    cst.widthUnit = widthUnit;
    cst.heightUnit = heightUnit;
    return cst;
}

typedef struct _ccBlendFunc
{
	unsigned int src;
	unsigned int dst;
} ccBlendFunc;

typedef NS_ENUM(unsigned char, CCPhysicsBodyType)
{
	CCPhysicsBodyTypeDynamic,
	CCPhysicsBodyTypeStatic,
};

#import "SKNode+CCBReader.h"
#import "SKPhysicsBody+CCBReader.h"
#import "SKTexture+CCBReader.h"

typedef double CCTime;
typedef SKColor CCColor;
typedef SKNode CCNode;
typedef SKPhysicsBody CCPhysicsBody;
typedef SKScene CCScene;
typedef SKSpriteNode CCSprite;
typedef SKTexture CCSpriteFrame;
typedef SKTexture CCTexture;

// just forward all unsupported features to a dummy class to make the compiler happy
@class CCBSpriteKitDummy;
typedef CCBSpriteKitDummy CCActionManager;
typedef CCBSpriteKitDummy CCDirector;
typedef CCBSpriteKitDummy CCSpriteFrameCache;
typedef CCBSpriteKitDummy OALSimpleAudio;

@class CCBSpriteKitDummyAction;
typedef CCBSpriteKitDummyAction CCAction;
typedef CCBSpriteKitDummyAction CCActionCallFunc;
typedef CCBSpriteKitDummyAction CCActionDelay;
typedef CCBSpriteKitDummyAction CCActionEase;
typedef CCBSpriteKitDummyAction CCActionEaseBackIn;
typedef CCBSpriteKitDummyAction CCActionEaseBackInOut;
typedef CCBSpriteKitDummyAction CCActionEaseBackOut;
typedef CCBSpriteKitDummyAction CCActionEaseBounceIn;
typedef CCBSpriteKitDummyAction CCActionEaseBounceInOut;
typedef CCBSpriteKitDummyAction CCActionEaseBounceOut;
typedef CCBSpriteKitDummyAction CCActionEaseElasticIn;
typedef CCBSpriteKitDummyAction CCActionEaseElasticInOut;
typedef CCBSpriteKitDummyAction CCActionEaseElasticOut;
typedef CCBSpriteKitDummyAction CCActionEaseIn;
typedef CCBSpriteKitDummyAction CCActionEaseInOut;
//typedef CCBSpriteKitDummy CCActionEaseInstant;
typedef CCBSpriteKitDummyAction CCActionEaseOut;
typedef CCBSpriteKitDummyAction CCActionFadeTo;
typedef CCBSpriteKitDummyAction CCActionHide;
typedef CCBSpriteKitDummyAction CCActionInstant;
typedef CCBSpriteKitDummyAction CCActionInterval;
typedef CCBSpriteKitDummyAction CCActionMoveTo;
typedef CCBSpriteKitDummyAction CCActionScaleTo;
typedef CCBSpriteKitDummyAction CCActionSequence;
typedef CCBSpriteKitDummyAction CCActionShow;
typedef CCBSpriteKitDummyAction CCActionSkewTo;
typedef CCBSpriteKitDummyAction CCActionTintTo;
