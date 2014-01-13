//
//  CCBSpriteKitReader.h
//  SpriteKitReader-Experimental
//
//  Created by Steffen Itterheim on 13/01/14.
//  Copyright (c) 2014 Steffen Itterheim. All rights reserved.
//

#import "CCBReader.h"

@interface CCBSpriteKitReader : CCBReader
{
	@private
	CGSize _sceneSize;
}

-(void) setSceneSize:(CGSize)sceneSize;

@end
