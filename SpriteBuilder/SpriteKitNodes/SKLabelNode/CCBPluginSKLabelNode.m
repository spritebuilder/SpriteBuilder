//
//  CCBPNode.m
//  SpriteBuilder
//
//  Created by Viktor on 12/17/13.
//
//

#import "CCBPluginSKLabelNode.h"

@implementation CCBPluginSKLabelNode
{
	NSInteger _verticalAlignmentMode;
	NSInteger _horizontalAlignmentMode;
}
SKNODE_COMPATIBILITY_CODE

-(void) initNode
{
	_horizontalAlignmentMode = SKLabelHorizontalAlignmentModeCenter;
	_verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
	
	self.horizontalAlignment = CCTextAlignmentCenter;
	self.verticalAlignment = CCVerticalTextAlignmentCenter;
}

-(void) setText:(NSString *)text
{
	self.string = text;
}
-(NSString*) text
{
	return self.string;
}

-(void) setAnchorPoint:(CGPoint)anchorPoint
{
	// SK labels don't have an anchorPoint, do not allow a custom anchorPoint
}

#pragma mark Alignment Modes

-(CGFloat) anchorPointYForVerticalAlignmentMode:(SKLabelVerticalAlignmentMode)verticalAlignmentMode
{
	CGFloat yAnchor = 0.0;
	NSFont* font = [NSFont fontWithName:self.fontName size:self.fontSize];
	//NSLog(@"FONT: %@ asc: %f desc: %f - heights: cap: %f x: %f", font, font.ascender, font.descender, font.capHeight, font.xHeight);
	
	switch (verticalAlignmentMode)
	{
		case SKLabelVerticalAlignmentModeBaseline:
			yAnchor = fabs(font.descender) / self.contentSize.height;
			break;
		case SKLabelVerticalAlignmentModeCenter:
			// not supported, depends on actual string contents
			break;
		case SKLabelVerticalAlignmentModeTop:
			// not supported, depends on actual string contents
			yAnchor = 1.0;
			break;
		case SKLabelVerticalAlignmentModeBottom:
			// not supported, depends on actual string contents
			yAnchor = 0.0;
			break;
			
		default:
			break;
	}
	
	return yAnchor;
}

-(void) setVerticalAlignmentMode:(NSInteger)verticalAlignmentMode
{
	_isTransformDirty = YES;
	_verticalAlignmentMode = verticalAlignmentMode;
	
	switch (_verticalAlignmentMode)
	{
			// FIXME: cocos2d text alignments seem to have no effect, emulating it via anchorPoint (which SKLabelNode doesn't have, so that works fine)
		case SKLabelVerticalAlignmentModeBaseline:
			//self.verticalAlignment = CCVerticalTextAlignmentCenter;
			// TODO: how to find baseline?
			_anchorPoint = CGPointMake(_anchorPoint.x, [self anchorPointYForVerticalAlignmentMode:_verticalAlignmentMode]);
			break;
		case SKLabelVerticalAlignmentModeCenter:
			//self.verticalAlignment = CCVerticalTextAlignmentCenter;
			_anchorPoint = CGPointMake(_anchorPoint.x, [self anchorPointYForVerticalAlignmentMode:_verticalAlignmentMode]);
			break;
		case SKLabelVerticalAlignmentModeTop:
			//self.verticalAlignment = CCVerticalTextAlignmentTop;
			_anchorPoint = CGPointMake(_anchorPoint.x, [self anchorPointYForVerticalAlignmentMode:_verticalAlignmentMode]);
			break;
		case SKLabelVerticalAlignmentModeBottom:
			//self.verticalAlignment = CCVerticalTextAlignmentBottom;
			_anchorPoint = CGPointMake(_anchorPoint.x, [self anchorPointYForVerticalAlignmentMode:_verticalAlignmentMode]);
			break;
			
		default:
			[NSException raise:NSInvalidArgumentException format:@"vertical alignment mode %i not implemented", (int)verticalAlignmentMode];
			break;
	}
}
-(NSInteger) verticalAlignmentMode
{
	return _verticalAlignmentMode;
}

-(void) setHorizontalAlignmentMode:(NSInteger)horizontalAlignmentMode
{
	_isTransformDirty = YES;
	_horizontalAlignmentMode = horizontalAlignmentMode;
	switch (_horizontalAlignmentMode)
	{
			// FIXME: cocos2d text alignments seem to have no effect, emulating it via anchorPoint (which SKLabelNode doesn't have, so that works fine)
		case SKLabelHorizontalAlignmentModeCenter:
			//self.horizontalAlignment = CCTextAlignmentCenter;
			_anchorPoint = CGPointMake(0.5, _anchorPoint.y);
			break;
		case SKLabelHorizontalAlignmentModeLeft:
			//self.horizontalAlignment = CCTextAlignmentLeft;
			_anchorPoint = CGPointMake(0.0, _anchorPoint.y);
			break;
		case SKLabelHorizontalAlignmentModeRight:
			//self.horizontalAlignment = CCTextAlignmentRight;
			_anchorPoint = CGPointMake(1.0, _anchorPoint.y);
			break;
			
		default:
			[NSException raise:NSInvalidArgumentException format:@"horizontal alignment mode %i not implemented", (int)_horizontalAlignmentMode];
			break;
	}
}
-(NSInteger) horizontalAlignmentMode
{
	return _horizontalAlignmentMode;
}

@end
