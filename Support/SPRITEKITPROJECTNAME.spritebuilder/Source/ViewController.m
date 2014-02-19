//
//  ViewController.m
//  SPRITEKITPROJECTNAME
//
//  Created by Steffen Itterheim on 24/01/14.
//

#import "ViewController.h"
#import "MainScene.h"
#import "SB+KoboldKit.h"

@implementation ViewController

-(void) presentFirstScene
{
	KKView* kkView = self.kkView;
	kkView.showsFPS = YES;
	kkView.showsNodeCount = YES;
	kkView.showsDrawCount = YES;
	kkView.showsCPUStats = YES;
	kkView.showsGPUStats = YES;

	[CCBReader setSceneSize:kkView.bounds.size];
	SKScene* scene = [CCBReader loadAsScene:@"MainScene.ccbi"];
	scene.scaleMode = SKSceneScaleModeAspectFit;
	
	scene.anchorPoint = CGPointMake(0.5, 0.5);
	[scene.children.firstObject setPosition:CGPointMake(200, 200)];
	
	[kkView presentScene:scene];
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
