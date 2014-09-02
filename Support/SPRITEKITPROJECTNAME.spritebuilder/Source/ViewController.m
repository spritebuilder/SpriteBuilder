//
//  ViewController.m
//  SPRITEKITPROJECTNAME
//
//  Created by Steffen Itterheim on 24/01/14.
//

#import "ViewController.h"
#import "SB+SpriteKit.h"
#import "MainScene.h"

@implementation ViewController

-(void) viewWillLayoutSubviews
{
	SKView* skView = (SKView*)self.view;
	NSAssert1([skView isKindOfClass:[SKView class]], @"ViewController's view is not a SKView instance, its class is: %@", NSStringFromClass([skView class]));
	
	// only present the scene if there's no scene currently presented
	// Note: viewWillLayoutSubviews will run every time the device is rotated or the view resizes, therefore this check is essential
	if (skView.scene == nil)
	{
		skView.showsFPS = YES;
		skView.showsNodeCount = YES;
		skView.showsDrawCount = YES;
		
		// additional undocumented debug flags
		[skView setValue:@(YES) forKey:@"_showsCulledNodesInNodeCount"]; // shows total node count next to visible node count
		//[skView setValue:@(YES) forKey:@"_showsGPUStats"];
		//[skView setValue:@(YES) forKey:@"_showsCPUStats"];
		
		// load the 'MainScene' from CCB
		NSString* sceneName = @"MainScene";
		SKScene* scene = [CCBReader loadAsScene:sceneName size:skView.bounds.size];
		NSAssert1(scene, @"unable to load scene '%@' - CCBReader returned 'nil', check for error messages earlier in the log", sceneName);
		[skView presentScene:scene];
	}
}

-(BOOL) shouldAutorotate
{
    return YES;
}

-(NSUInteger) supportedInterfaceOrientations
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
	{
        return UIInterfaceOrientationMaskAllButUpsideDown;
    }
	else
	{
        return UIInterfaceOrientationMaskAll;
    }
}

-(void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

@end
