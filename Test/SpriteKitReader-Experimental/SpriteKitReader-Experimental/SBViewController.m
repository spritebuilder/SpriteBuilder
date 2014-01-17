//
//  SBViewController.m
//  SpriteKitReader-Experimental
//
//  Created by Steffen Itterheim on 09/01/14.
//  Copyright (c) 2014 Steffen Itterheim. All rights reserved.
//

#import "SBViewController.h"
#import "SBMyScene.h"
#import "CCBReader.h"

@implementation SBViewController

- (void) viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    SKView* skView = (SKView *)self.view;
	if (skView.scene == nil)
	{
		skView.showsFPS = YES;
		skView.showsNodeCount = YES;
		
		// Create and configure the scene.
		[CCBReader setSceneSize:skView.bounds.size];
		SKScene* scene = [CCBReader loadAsScene:@"MainScene"];
		NSLog(@"scene %@ %p: %@", NSStringFromClass([scene class]), scene, scene);
		scene.scaleMode = SKSceneScaleModeResizeFill;

		SKSpriteNode* s = [SKSpriteNode spriteNodeWithColor:[SKColor redColor] size:CGSizeMake(10, 10)];
		s.texture = [SKTexture textureWithImageNamed:@"Published-iOS/resources-phone/bird.png"];
		s.size = s.texture.size;
		s.xScale = 5;
		NSLog(@"tex: %@", s.texture);
		s.position = CGPointMake(100, 100);
		[scene addChild:s];
		
		[skView presentScene:scene];
		
		for (SKNode* node in [scene.children.firstObject children])
		{
			NSLog(@"node: %@", node);
			if ([node isKindOfClass:[SKSpriteNode class]])
			{
				//[(SKSpriteNode*)node setYScale:3.0];
				//[node setValue:[NSNumber numberWithFloat:3.0] forKey:@"yScale"];
			}
		}
	}
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

@end
