//
//  CCAnimation_Tests.m
//  SpriteBuilder
//
//  Created by John Twigg on 6/9/14.
//
//

#import <XCTest/XCTest.h>
#import "cocos2d.h"
#import "CCBXCocos2diPhone.h"
#import "PlugInManager.h"
#import "PlugInExport.h"
#import "CCBReader.h"
#import "CCAnimationManager.h"
#import "CCAnimationManager_Private.h"
#import "CCBSequence.h"
#import "Cocos2dTestHelpers.h"

#define IS_NEAR(a,b,accuracy) (fabsf(a - b) < kAccuracy)

const float kDelta = 0.1f;//100ms;
const CGFloat kAccuracy = 0.01f;


@implementation CCAnimationManager (Test)

-(CCBSequence*)runningSequence
{
	return _runningSequence;
}

@end

typedef void (^CallbackBlock) ();
@interface CCAnimationDelegateTester : NSObject<CCBAnimationManagerDelegate>
{
	CallbackBlock _sequenceFinished;
}


@end




@implementation CCAnimationDelegateTester
{
	NSMutableDictionary * methodBlocks;
	
}

-(void)setSequenceFinishedCallback:(CallbackBlock)sequenceFinished
{
	_sequenceFinished = [sequenceFinished copy];
}

-(void)registerMethod:(NSString*)callback block:(CallbackBlock)block
{
	if(methodBlocks == nil)
	{
		methodBlocks = [NSMutableDictionary dictionary];
	}
	
	methodBlocks[callback] = [block copy];
}

void dynamicMethodIMP(CCAnimationDelegateTester * self, SEL _cmd)
{
	NSString * selectorName = NSStringFromSelector(_cmd);
	if(self->methodBlocks[selectorName])
	{
		CallbackBlock block =self->methodBlocks[selectorName];
		block();
	}
}

+(BOOL)resolveInstanceMethod:(SEL)sel
{
	if(![super resolveInstanceMethod:sel])
	{
		class_addMethod([self class], sel, (IMP) dynamicMethodIMP, "v@:");
		return YES;
	}

			
	return YES;
}


- (void) completedAnimationSequenceNamed:(NSString*)name
{
	if(_sequenceFinished)
		_sequenceFinished();
}

@end

@interface CCAnimation_Tests : XCTestCase

@end

@implementation CCAnimation_Tests

- (void)setUp
{
    [super setUp];
	

	
	
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}



- (void)testAnimationSync1
{
	CCAnimationDelegateTester * callbackTest = [[CCAnimationDelegateTester alloc] init];
	
	NSData * animData = [Cocos2dTestHelpers readCCB:@"AnimationTest1"];
	XCTAssertNotNil(animData, @"Can't find ccb File");
	if(!animData)
		return;

	CCBReader * reader = [CCBReader reader];
	CCNode * rootNode = [reader loadWithData:animData owner:callbackTest];
	
	CCNode * node0 = rootNode.children[0];
	CCNode * node1 = rootNode.children[1];
	CCNode * node2 = rootNode.children[2];
	
	
	XCTAssertTrue([node0.name isEqualToString:@"node0"]);
	XCTAssertTrue([node1.name isEqualToString:@"node1"]);
	XCTAssertTrue([node2.name isEqualToString:@"node2"]);
	 
	
	const CGFloat kTranslation = 500.0f;
	
	
	float totalElapsed = 0.0f;
	__block float currentAnimElapsed = 0.0f;
	
	CCBSequence * seq = rootNode.animationManager.sequences[0];
	
	[rootNode.animationManager setCompletedAnimationCallbackBlock:^(CCAnimationManager * manager) {
		XCTAssertTrue(fabsf(currentAnimElapsed - seq.duration) < kAccuracy, @"The animation should have taken 4 seconds. Possible divergenc.");

		currentAnimElapsed = 0.0f;
	}];
	
	while(totalElapsed <= seq.duration * 20)
	{
		[rootNode.animationManager update:kDelta];
		
		totalElapsed += kDelta;
		currentAnimElapsed += kDelta;

		float timeIntoSeq = rootNode.animationManager.runningSequence.time;

		//This animation specifcally see's all three nodes translate after three seconds back to the root pos.
		if(timeIntoSeq >= 3.0f)
		{
			//All final translations go from x=500 -> x=0 over 1 second.
			float perentageIntroSyncedTranlation = 1.0f - (seq.duration - timeIntoSeq);
			float desiredXCoord = (1.0f - perentageIntroSyncedTranlation) * kTranslation;
			
			XCTAssertTrue(fabsf(node0.position.x - node1.position.x) < kAccuracy, @"They should all equal each other");
			XCTAssertTrue(fabsf(node0.position.x - node2.position.x) < kAccuracy, @"They should all equal each other");
			XCTAssertTrue(fabsf(node0.position.x - desiredXCoord) < kAccuracy,	  @"They should all equal each desiredXCoord. Possible divergenc. XPos:%0.2f DesiredPos:%0.2f totalElapsed:%0.2f", node0.position.x,desiredXCoord, totalElapsed);
			
		}
	}
}

-(void)testAnimationCallback1
{
	
	CCAnimationDelegateTester * callbackTest = [[CCAnimationDelegateTester alloc] init];

	NSData * animData = [Cocos2dTestHelpers readCCB:@"AnimationTest1"];
	XCTAssertNotNil(animData, @"Can't find ccb File");
	if(!animData)
		return;

	CCBReader * reader = [CCBReader reader];
	CCNode * rootNode = [reader loadWithData:animData owner:callbackTest];
	
	CCBSequence * seq = rootNode.animationManager.sequences[0];
	rootNode.animationManager.delegate = callbackTest;
	
	
	float totalElapsed = 0.0f;
	__block float currentAnimElapsed = 0.0f;
	
	[callbackTest setSequenceFinishedCallback:^{
		currentAnimElapsed = 0.0f;
	}];
	
	
	__block BOOL middleCallbackWasCalled = NO;
	
	[callbackTest registerMethod:@"onMiddleOfAnimation" block:^{
		XCTAssertTrue(fabsf(currentAnimElapsed - seq.duration /2.0f) < kAccuracy, @"Not in the middle of the sequence");
		middleCallbackWasCalled = YES;
	}];
	
	__block BOOL endCallbackWasCalled = NO;
	[callbackTest registerMethod:@"onEndOfAnim1" block:^{
		XCTAssertTrue(fabsf(currentAnimElapsed) < kAccuracy, @"Should be at the end of the frame, however its been looped so its Zero.");
		endCallbackWasCalled = YES;
	}];
	

	while(totalElapsed <= seq.duration * 20)
	{
		[rootNode.animationManager update:kDelta];
		
		totalElapsed += kDelta;
		currentAnimElapsed += kDelta;
		
	}

	XCTAssert(middleCallbackWasCalled, @"Middle Callback should be called");
	XCTAssert(endCallbackWasCalled, @"End callback should be called");
		
}


//This test file  "AnimationTest2.ccb" has two animations. T1 and T2.
//The test ensures that when T1 ends, we launch T2 with a tween of 100ms.
-(void)testAnimationTween1
{
	
	CCAnimationDelegateTester * callbackTest = [[CCAnimationDelegateTester alloc] init];
	
	NSData * animData = [Cocos2dTestHelpers readCCB:@"AnimationTest2"];
	XCTAssertNotNil(animData, @"Can't find ccb File");
	if(!animData)
		return;

	CCBReader * reader = [CCBReader reader];
	CCNode * rootNode = [reader loadWithData:animData owner:callbackTest];
	CCNode * node0 = rootNode.children[0];
	
	XCTAssertTrue([node0.name isEqualToString:@"node0"]);
	
	CCBSequence * seq = rootNode.animationManager.sequences[0];
	rootNode.animationManager.delegate = callbackTest;
	
	const CGFloat kXTranslation = 500.0f;
	const CGFloat kYTranslation = 200.0f;
	const CGFloat kTween = 1.0f;
	
	float totalElapsed = 0.0f;
	__block BOOL firstTime = YES;
	__block float currentAnimElapsed = 0.0f;
	__block BOOL playingDefaultAnimToggle = YES;
	
	[callbackTest setSequenceFinishedCallback:^{
		
		//When the animation finished, Toggle over to the next T1/T2 animation.
		firstTime = NO;
		playingDefaultAnimToggle = !playingDefaultAnimToggle;
		[rootNode.animationManager runAnimationsForSequenceNamed:playingDefaultAnimToggle ? @"T1" : @"T2" tweenDuration:kTween];

		//Reset clock.
		currentAnimElapsed = 0.0f;
	}];
	
	//
	
	typedef void (^ValidateAnimation) (float timeIntoAnimation);
	
	ValidateAnimation validationAnimBlock =^(float timeIntoAnimation)
	{
		//We're in T1 + tween. Ensure valid
		//Also, always skip frame 0.
		
		if(timeIntoAnimation < 0.0f || IS_NEAR(timeIntoAnimation,0.0f,kAccuracy))
		{
			return;
		}
		else if(timeIntoAnimation < 1.0f || IS_NEAR(timeIntoAnimation,1.0f,kAccuracy))
		{
			
			float percentage = (timeIntoAnimation - kDelta);
			float xCoord =  kXTranslation * (percentage);
			XCTAssertEqualWithAccuracy(node0.position.x, xCoord, kAccuracy, @"They should all equal each other");
		}
		else if(timeIntoAnimation < 3.0f || IS_NEAR(timeIntoAnimation,3.0f,kAccuracy))
		{
			XCTAssertEqualWithAccuracy(node0.position.x, kXTranslation, kAccuracy, @"Error: timeIntoAnim:%0.2f", timeIntoAnimation);
		}
		else if(timeIntoAnimation  < 4.0f || IS_NEAR(timeIntoAnimation,4.0f,kAccuracy))
		{
			
			float percentage = (timeIntoAnimation  - 3.0f);
			float xCoord = kXTranslation * (1.0f - percentage);
			XCTAssertEqualWithAccuracy(node0.position.x, xCoord, kAccuracy, @"They should all equal each other");
		}

	};
	
	
	while(totalElapsed <= (seq.duration + kTween) * 20)
	{
		totalElapsed += kDelta;
		currentAnimElapsed += kDelta;
		
		[rootNode.animationManager update:kDelta];
				
		if(firstTime)
		{
			validationAnimBlock(currentAnimElapsed);
			continue;
		}
		
		
		if(!playingDefaultAnimToggle)
		{
			//Playing T2 animation.
			
			//In tween and greather that the first frame, as the first frame stutters.
			if(currentAnimElapsed < kTween || IS_NEAR(currentAnimElapsed, kTween,kAccuracy))
			{
				//Skip first frame as it halts for one frme.
				if(currentAnimElapsed < kDelta)
					continue;

				
				//All final translations go from y=200 -> y=0
				float percentage = (currentAnimElapsed - kDelta)/ kTween;
				float yCoord = kYTranslation * (1.0f - percentage);
				
				XCTAssertEqualWithAccuracy(node0.position.y, yCoord, kAccuracy, @"They should all equal each other");
			}
			else
			{
				float timeIntoAnimation = currentAnimElapsed - kTween;
				validationAnimBlock(timeIntoAnimation);
			}

		}
		else //Playing T1 animation.
		{
			//Ensure tween from T2(end) -> T1(start)
			if(currentAnimElapsed < kTween)
			{
				//Skip first frame as it halts for one frme.
				if(currentAnimElapsed < kDelta)
					continue;
				
				//Should interpolate from y= 0 -> y = 200;
				float percentage = (currentAnimElapsed - kDelta)/ kTween;
				float yCoord = kYTranslation * (percentage);
				
				XCTAssertEqualWithAccuracy(node0.position.y, yCoord, kAccuracy, @"They should all equal each other");
			}
			else
			{
				float timeIntoAnimation = currentAnimElapsed - kTween;
				validationAnimBlock(timeIntoAnimation);
			}
		}
	}
	
}


//This test file  "AnimationTest3.ccb".
//The test ensures that default animation loops properly.
-(void)testAnimationLoop1
{
	CCAnimationDelegateTester * callbackHelper = [[CCAnimationDelegateTester alloc] init];
	
	NSData * animData = [Cocos2dTestHelpers readCCB:@"AnimationTest3"];
	XCTAssertNotNil(animData, @"Can't find ccb File");
	if(!animData)
		return;

	CCBReader * reader = [CCBReader reader];
	CCNode * rootNode = [reader loadWithData:animData owner:callbackHelper];
	CCNode * node0 = rootNode.children[0];
	
	XCTAssertTrue([node0.name isEqualToString:@"node0"]);
	
	CCBSequence * seq = rootNode.animationManager.sequences[0];
	rootNode.animationManager.delegate = callbackHelper;
	
	const CGFloat kXTranslation = 500.0f;

	
	float totalElapsed = 0.0f;
	__block BOOL firstTime = YES;
	__block float currentAnimElapsed = 0.0f;

	[callbackHelper setSequenceFinishedCallback:^{
		
		//When the animation finished, Toggle over to the next T1/T2 animation.
		firstTime = NO;
		
		//Reset clock.
		currentAnimElapsed = 0.0f;
	}];
	
	[rootNode.animationManager update:0];//Zero'th update.
	
	while(totalElapsed <= (seq.duration * 20))
	{
		totalElapsed += kDelta;
		currentAnimElapsed += kDelta;
		
		[rootNode.animationManager update:kDelta];
		
		if(currentAnimElapsed <= 1.0f || IS_NEAR(currentAnimElapsed, 1.0f, kAccuracy))
		{
			float percentage = currentAnimElapsed;
			XCTAssertEqualWithAccuracy(node0.position.x, percentage * kXTranslation, kAccuracy, @"Should be equial: Elapsed:%0.2f", totalElapsed);
		}
		else
		{
			//We should be translating from X = 500 -> x = 0;
			float percentage = currentAnimElapsed - 1.0f;
			float xCoord = kXTranslation * (1.0f - percentage);
			
			XCTAssertEqualWithAccuracy(node0.position.x, xCoord, kAccuracy, @"Should be equial: Elapsed:%0.2f", totalElapsed);
			
		}
	}
}



//This test file  "AnimationTest4.ccb".
//The test ensures that seeking into the middle of an animation works.
-(void)testAnimationSeeking1
{
	
	NSData * animData = [Cocos2dTestHelpers readCCB:@"AnimationTest4"];
	XCTAssertNotNil(animData, @"Can't find ccb File");
	if(!animData)
		return;

	CCBReader * reader = [CCBReader reader];
	CCNode * rootNode = [reader loadWithData:animData owner:nil];
	CCNode * node0 = rootNode.children[0];
	
	XCTAssertTrue([node0.name isEqualToString:@"node0"]);
	
	CCBSequence * seq = rootNode.animationManager.sequences[0];
	
	const CGFloat kXTranslation = 500.0f;
	
	float totalElapsed = 0.0f;

	[rootNode.animationManager jumpToSequenceNamed:seq.name time:seq.duration/2.0f];

	totalElapsed =seq.duration/2.0f;//move time forward because we've seeked.
	while(totalElapsed <= (seq.duration * 2))
	{
		if(totalElapsed <= seq.duration || IS_NEAR(totalElapsed, seq.duration, kAccuracy))
		{
			float percentage = totalElapsed/seq.duration;
			XCTAssertEqualWithAccuracy(node0.position.x, percentage * kXTranslation, kAccuracy, @"Should be equial: Elapsed:%0.2f", totalElapsed);
		}
		else
		{
			XCTAssertEqualWithAccuracy(node0.position.x, kXTranslation, kAccuracy, @"Should be equial: Elapsed:%0.2f", totalElapsed);
		}
		
		//Update at end of loop.
		totalElapsed += kDelta;
		[rootNode.animationManager update:kDelta];

	}
	
	/////////////	/////////////	/////////////	/////////////	/////////////	/////////////
	//T2 Test
	totalElapsed = 0.0f;
	const float kT2Duration = 3.0f;
	const float kSkipDuration = 1.0f;
	[rootNode.animationManager jumpToSequenceNamed:@"T2" time:kSkipDuration];
	totalElapsed = kSkipDuration;
	
	totalElapsed =seq.duration/2.0f;//move time forward because we've seeked.
	while(totalElapsed <= (kT2Duration * 2))
	{
		if(totalElapsed <= kT2Duration || IS_NEAR(totalElapsed, kT2Duration, kAccuracy))
		{
			float percentage = (totalElapsed - kSkipDuration)/2.0f;
			XCTAssertEqualWithAccuracy(node0.position.x, percentage * kXTranslation, kAccuracy, @"Should be equial: Elapsed:%0.2f", totalElapsed);
		}
		else
		{
			XCTAssertEqualWithAccuracy(node0.position.x, kXTranslation, kAccuracy, @"Should be equial: Elapsed:%0.2f", totalElapsed);
		}
		
		//Update at end of loop.
		totalElapsed += kDelta;
		[rootNode.animationManager update:kDelta];
		
	}
	
}

//ANIMATION SHOUld chain from T1->T2->T1->T2....
-(void)testAnimationChaining1
{
	
	NSData * animData = [Cocos2dTestHelpers readCCB:@"AnimationTest5"];
	XCTAssertNotNil(animData, @"Can't find ccb File");
	if(!animData)
		return;
	
	CCBReader * reader = [CCBReader reader];
	CCNode * rootNode = [reader loadWithData:animData owner:nil];
	
	const CGFloat kAnimationDuration = 1.0f;
	float totalElapsed = 0.0f;
	

	while(totalElapsed < (kAnimationDuration * 29))
	{
		[rootNode.animationManager update:kDelta];
		totalElapsed += kDelta;
	}
	float overHang  = fmodf(totalElapsed, 1.0f);
	
	XCTAssert([rootNode.animationManager.runningSequence.name isEqualToString:@"T2"], @"Should be on sequence T2");
	XCTAssertEqualWithAccuracy(rootNode.animationManager.runningSequence.time, overHang, kAccuracy, @"Should be at the start of T2 animation");

}


//In T3 animation, it goes from invisible to visible after 2 seconds.
-(void)testVisibility1
{
	
	NSData * animData = [Cocos2dTestHelpers readCCB:@"AnimationTest5"];
	XCTAssertNotNil(animData, @"Can't find ccb File");
	if(!animData)
		return;
	
	CCBReader * reader = [CCBReader reader];
	CCNode * rootNode = [reader loadWithData:animData owner:nil];

	CCNode * node0 = rootNode.children[0];
	XCTAssertTrue([node0.name isEqualToString:@"node0"]);

	[rootNode.animationManager runAnimationsForSequenceNamed:@"T3"];
	XCTAssert(!node0.visible, @"should be invisible");
	
	float totalElapsed = 0.0f;
	
	while(totalElapsed <= (2.0f) || IS_NEAR(totalElapsed, 2.0f, kAccuracy))
	{
		[rootNode.animationManager update:kDelta];
		totalElapsed += kDelta;
	}

	//Should be visible after three seconds.
	XCTAssert(node0.visible, @"should be visible");

}


//In T4 animation, the duration is Zero.
-(void)testZeroDurationTimeline1
{
	
	NSData * animData = [Cocos2dTestHelpers readCCB:@"AnimationTest5"];
	XCTAssertNotNil(animData, @"Can't find ccb File");
	if(!animData)
		return;
	
	CCBReader * reader = [CCBReader reader];
	CCNode * rootNode = [reader loadWithData:animData owner:nil];
	
	CCNode * node0 = rootNode.children[0];
	XCTAssertTrue([node0.name isEqualToString:@"node0"]);
	
	[rootNode.animationManager runAnimationsForSequenceNamed:@"T4"];
	
	XCTAssert([rootNode.animationManager.runningSequenceName isEqualToString:@"T4"], @"wrong anim");
	XCTAssertEqual(rootNode.animationManager.runningSequence.duration, 0.0f, @"Should be zero lenght");
		
	[rootNode.animationManager update:kDelta];
	[rootNode.animationManager update:kDelta];
	[rootNode.animationManager update:kDelta];
	[rootNode.animationManager update:kDelta];
	
	//After enough trials, the animation should be finished.	
	XCTAssertNil(rootNode.animationManager.runningSequence, @"Should be nil");


}


@end
