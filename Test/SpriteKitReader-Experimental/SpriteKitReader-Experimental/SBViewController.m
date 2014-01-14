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

		[skView presentScene:scene];
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
