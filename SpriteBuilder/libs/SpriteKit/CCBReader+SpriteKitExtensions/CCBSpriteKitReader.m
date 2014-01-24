/*
 * SpriteBuilder: http://www.spritebuilder.org
 *
 * Copyright (c) 2014 Apportable Inc.
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


#import "CCBSpriteKitReader.h"
#import "JRSwizzle.h"

@implementation CCBSpriteKitReader

-(id) init
{
	self = [super init];
	if (self)
	{
		[CCBReader configureCCFileUtils];
		
		[self swizzleMethodNamed:@"setAnchorPoint:" classNames:@[@"SKScene", @"SKSpriteNode", @"SKVideoNode"]];
	}
	return self;
}

-(void) swizzleMethodNamed:(NSString*)methodName classNames:(NSArray*)classNames
{
	for (NSString* className in classNames)
	{
		[self swizzleMethodNamed:methodName className:className];
	}
}

-(void) swizzleMethodNamed:(NSString*)methodName className:(NSString*)className
{
	NSError* error = nil;
	Class klass = NSClassFromString(className);
	NSAssert2(klass, @"CCBSpriteKitReader: unknown class '%@' - can't swizzle method '%@'", className, methodName);
	
	NSString* newMethod = [NSString stringWithFormat:@"ccb_%@", methodName];
	[klass jr_swizzleMethod:NSSelectorFromString(methodName)
				 withMethod:NSSelectorFromString(newMethod)
					  error:&error];
	NSAssert2(error == nil, @"CCBSpriteKitReader: method '%@' swizzle error: %@", methodName, error);
}

-(CCNode*) nodeFromClassName:(NSString *)nodeClassName
{
	// map CC nodes to SK nodes
	CCNode* node = nil;

	if ([nodeClassName isEqualToString:@"CCNode"])
	{
		node = [SKNode node];
	}
	else if ([nodeClassName isEqualToString:@"CCSprite"] ||
			 [nodeClassName isEqualToString:@"CCNodeColor"] ||
			 [nodeClassName isEqualToString:@"CCNodeGradient"])
	{
		node = [SKSpriteNode node];
	}
	else if ([nodeClassName isEqualToString:@"SKColorSpriteNode"])
	{
		node = [SKSpriteNode spriteNodeWithColor:[SKColor magentaColor] size:CGSizeMake(32, 32)];
	}
	else if ([nodeClassName isEqualToString:@"CCLabelTTF"])
	{
		node = [SKLabelNode node];
	}
	else if ([nodeClassName isEqualToString:@"CCParticleSystem"])
	{
		node = [SKEmitterNode node];
	}
	else
	{
		Class nodeClass = NSClassFromString(nodeClassName);
		node = [[nodeClass alloc] init];
	}

#if DEBUG
	NSLog(@" ");
	NSLog(@"~~~~~~~~~~~~~~~~~~ %@ - %p ~~~~~~~~~~~~~~~~~~", nodeClassName, node);
	if ([node class] != NSClassFromString(nodeClassName))
	{
		NSLog(@"MAPPED CLASS: %@ => %@", nodeClassName, NSStringFromClass([node class]));
	}
#endif

	return node;
}

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
