//
//  CCBSpriteKitReader.m
//  SpriteKitReader-Experimental
//
//  Created by Steffen Itterheim on 13/01/14.
//  Copyright (c) 2014 Steffen Itterheim. All rights reserved.
//

#import "CCBSpriteKitReader.h"

@implementation CCBSpriteKitReader

-(id) init
{
	self = [super init];
	if (self)
	{
		[CCBReader configureCCFileUtils];
	}
	return self;
}

/*
-(CCNode*) nodeFromClass:(Class)nodeClass
{
	// map CC nodes to SK nodes
	CCNode* node = nil;
	
	node = [nodeClass node];

	return node;
}
*/

-(void) setSceneSize:(CGSize)sceneSize
{
	_sceneSize = sceneSize;
}

-(CCScene*) createScene
{
	if (CGSizeEqualToSize(_sceneSize, CGSizeZero))
	{
		// if the size hasn't been set manually, try to get it programmatically instead
		// this may not work in all cases, specifically if at the time of loading a CCB the Sprite Kit view isn't the rootView
		UIWindow* window = [UIApplication sharedApplication].windows.firstObject;
		UIView* rootView = window.rootViewController.view;
		CGRect screenFrame = [UIScreen mainScreen].bounds;
		CGRect viewFrame = [rootView convertRect:screenFrame fromView:nil];
		_sceneSize = viewFrame.size;
		NSAssert(CGSizeEqualToSize(_sceneSize, CGSizeZero) == NO, @"Sprite Kit scene size is zero. Use [CCBReader setSceneSize: ..] before loading from CCB.");
	}
	
	return [SKScene sceneWithSize:_sceneSize];
}

#pragma mark Property Overrides

-(void) readerDidSetSpriteFrame:(CCSpriteFrame*)spriteFrame node:(CCNode*)node
{
	[node setValue:[NSValue valueWithCGSize:spriteFrame.size] forKey:@"size"];
}

@end
