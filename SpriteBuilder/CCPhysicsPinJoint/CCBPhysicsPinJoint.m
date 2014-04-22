//
//  CCBPhysicsPinJoint.m
//  SpriteBuilder
//
//  Created by John Twigg on 2/19/14.
//
//

#import "CCBPhysicsPinJoint.h"
#import "AppDelegate.h"
#import "GeometryUtil.h"




@interface CCBPhysicsJoint()
-(void)updateSelectionUI;
@end

@interface CCBPhysicsPinJoint()
{


    
    CCSprite        * minHandle;
    CCSprite9Slice  * minHandleBody;
    CCSprite        * maxHandle;
    CCSprite9Slice  * maxHandleBody;
    
}


@end

@implementation CCBPhysicsPinJoint
@synthesize minDistance;
@synthesize maxDistance;
@synthesize maxDistanceEnabled;
@synthesize minDistanceEnabled;


- (id) init
{
    self = [super init];
    if (self)
    {
        self.minDistance = [self localLength];
        self.maxDistance = [self localLength];

    }
    
    return self;
}


-(void)setupBody
{
    [super setupBody];
    
    maxHandle = [CCSprite spriteWithImageNamed:@"joint-distance-handle-long.png"];
    maxHandle.anchorPoint = ccp(0.5f, 0.0f);
    minHandle = [CCSprite spriteWithImageNamed:@"joint-distance-handle-short.png"];
    minHandle.anchorPoint = ccp(0.5f, 0.0f);
    [scaleFreeNode addChild:maxHandle];
    [scaleFreeNode addChild:minHandle];
    
    CCSizeType sizeType;
    sizeType.heightUnit = CCSizeUnitUIPoints;
    sizeType.widthUnit = CCSizeUnitUIPoints;
    
    maxHandleBody = [CCSprite9Slice spriteWithImageNamed:@"joint-distance-slide.png"];
    maxHandleBody.marginLeft = 0.0f;
    maxHandleBody.marginRight = kMargin;
    maxHandleBody.marginBottom = 0.0;
    maxHandleBody.marginTop = 0.0;
    maxHandleBody.scale = 1.0;
    maxHandleBody.anchorPoint = ccp(0.0f,0.5f);
    maxHandleBody.contentSizeType = sizeType;

    
    [scaleFreeNode addChild:maxHandleBody];
    
    
    minHandleBody = [CCSprite9Slice spriteWithImageNamed:@"joint-distance-slide.png"];
    minHandleBody.marginLeft = 0.0f;
    minHandleBody.marginRight = kMargin;
    minHandleBody.marginBottom = 0.0;
    minHandleBody.marginTop = 0.0;
    minHandleBody.scale = 1.0;
    minHandleBody.anchorPoint = ccp(0.0f,0.5f);
    minHandleBody.contentSizeType = sizeType;
    [scaleFreeNode addChild:minHandleBody];

}


-(void)updateRenderBody
{
    [super updateRenderBody];
    float length = [self worldLength];
    
       
    
    minHandle.position = ccpMult(ccp(length *  self.minDistance / [self localLength], kEdgeRadius - 1.0f),1/[CCDirector sharedDirector].contentScaleFactor);
    maxHandle.position = ccpMult(ccp(length *  self.maxDistance /[self localLength], kEdgeRadius - 1.0f),1/[CCDirector sharedDirector].contentScaleFactor);
    
    minHandleBody.contentSize = CGSizeMake(length *  self.minDistance / [self localLength] + kEdgeRadius, kEdgeRadius * 2.0f);
    maxHandleBody.contentSize = CGSizeMake(length *  self.maxDistance / [self localLength] + kEdgeRadius, kEdgeRadius * 2.0f);
 
}

-(void)visit:(CCRenderer *)renderer parentTransform:(const GLKMatrix4 *)parentTransform
{
    [self updateRenderBody];
    [super visit:renderer parentTransform:parentTransform];
}



-(JointHandleType)hitTestJointHandle:(CGPoint)worlPos
{
    {
        CGPoint pointMin = [maxHandle convertToNodeSpaceAR:worlPos];
        pointMin = ccpSub(pointMin, ccp(0,15.0f));
        if(ccpLength(pointMin) < 7.0f)
        {
            return MaxHandleType;
        }
    }

    {
        CGPoint pointMin = [minHandle convertToNodeSpaceAR:worlPos];
        pointMin = ccpSub(pointMin, ccp(0,2.0f));
        if(ccpLength(pointMin) < 7.0f)
        {
            return MinHandleType;
        }
    }
    
    return [super hitTestJointHandle:worlPos];;
}

-(void)updateSelectionUI
{
    //If selected, display selected sprites.
    if(selectedBodyHandle & (1 << EntireJoint))
    {
		if(self.maxDistanceEnabled && (self.bodyA && self.bodyB))
		{
			if(maxHandle.parent == nil)
				[scaleFreeNode addChild:maxHandle];
			
			if(maxHandleBody.parent == nil)
				[scaleFreeNode addChild:maxHandleBody];

		}
		else
		{
			if(maxHandle.parent != nil)
				[maxHandle removeFromParentAndCleanup:NO];
			
			if(maxHandleBody.parent != nil)
				[maxHandleBody removeFromParentAndCleanup:NO];
		}
		
		if(self.minDistanceEnabled  && (self.bodyA && self.bodyB))
		{
			if(minHandle.parent == nil)
				[scaleFreeNode addChild:minHandle];
			
			if(minHandleBody.parent == nil)
				[scaleFreeNode addChild:minHandleBody];
		}
		else
		{
			if(minHandle.parent != nil)
				[minHandle removeFromParentAndCleanup:NO];
			
			if(minHandleBody.parent != nil)
				[minHandleBody removeFromParentAndCleanup:NO];
		}
    }
    else //Unseleted
    {
		if(minHandle.parent != nil)
			[minHandle removeFromParentAndCleanup:NO];
		
		if(minHandleBody.parent != nil)
			[minHandleBody removeFromParentAndCleanup:NO];
		
		if(maxHandle.parent != nil)
			[maxHandle removeFromParentAndCleanup:NO];
		
		if(maxHandleBody.parent != nil)
			[maxHandleBody removeFromParentAndCleanup:NO];
    }
    
    if(selectedBodyHandle & (1 << MaxHandleType))
    {
        maxHandleBody.spriteFrame = [self frameWithImageNamed:@"joint-distance-slide-sel.png"];
    }
    else
    {
        maxHandleBody.spriteFrame = [self frameWithImageNamed:@"joint-distance-slide.png"];
    }

    if(selectedBodyHandle & (1 << MinHandleType))
    {
        minHandleBody.spriteFrame = [self frameWithImageNamed:@"joint-distance-slide-sel.png"];
    }
    else
    {
        minHandleBody.spriteFrame = [self frameWithImageNamed:@"joint-distance-slide.png"];
    }
    
    [super updateSelectionUI];
}



#pragma mark - Properties -



-(void)setAnchorA:(CGPoint)lAnchorA
{
    [super setAnchorA:lAnchorA];
    //refresh max mins
    self.minDistance = self.minDistance;
    self.maxDistance = self.maxDistance;
    
}


-(void)setAnchorB:(CGPoint)lAnchorB
{
    [super setAnchorB:lAnchorB];
    //refresh max mins
    self.minDistance = self.minDistance;
    self.maxDistance = self.maxDistance;
}



-(void)setBodyHandle:(CGPoint)worldPos bodyType:(JointHandleType)bodyType
{
    
    if(bodyType == MaxHandleType)
    {
        CGPoint localPoint = [self convertToNodeSpace:worldPos];
        self.maxDistance =  localPoint.x;
    }
    
    if(bodyType == MinHandleType)
    {
        CGPoint localPoint = [self convertToNodeSpace:worldPos];
        self.minDistance =  localPoint.x;
    }
    
    [super setBodyHandle:worldPos bodyType:bodyType];
}


-(float)minDistance
{
    return minDistance;
}

-(float)maxDistance
{
    return maxDistance;
}

-(void)setMinDistance:(float)lMinDistance
{
    minDistance = lMinDistance;
    
    if(self.isRunningInActiveScene)
    {
		if(self.isRunningInActiveScene && !minDistanceEnabled )
		{
			[self willChangeValueForKey:@"minDistance"];
			minDistance = [self localLength];
			[self didChangeValueForKey:@"minDistance"];
		}
		else
		{
			if(minDistance > [self localLength])
				minDistance = [self localLength];
			
			if(minDistance < 0)
				minDistance = 0;
		}
    }
    
	[[AppDelegate appDelegate] refreshProperty:@"minDistance"];
    
}


-(void)setMaxDistance:(float)lMaxDistance
{
    maxDistance = lMaxDistance;
    
    if(self.isRunningInActiveScene )
    {
		if(!maxDistanceEnabled)
		{
			[self willChangeValueForKey:@"maxDistance"];
			maxDistance = [self localLength];
			[self didChangeValueForKey:@"maxDistance"];
		}
		else
		{
			if(maxDistance < [self localLength])
				maxDistance = [self localLength];
		}
    }
   
    
    [[AppDelegate appDelegate] refreshProperty:@"maxDistance"];
}

-(BOOL)maxDistanceEnabled
{
    return maxDistanceEnabled;
}

-(void)setMaxDistanceEnabled:(BOOL)lMaxDistanceEnabled
{
	if((!self.bodyA || !self.bodyB) && self.isRunningInActiveScene)
	{
		[[AppDelegate appDelegate] modalDialogTitle:@"Assign Bodies" message:@"You must assign this joint to both BodyA and BodyB before editing the max distance"];
		return;
	}
	
    if(maxDistanceEnabled != lMaxDistanceEnabled)
    {
        maxDistanceEnabled = lMaxDistanceEnabled;
        
        maxDistance = [self localLength];
    }
}


-(BOOL)minDistanceEnabled
{
    return minDistanceEnabled;
}

-(void)setMinDistanceEnabled:(BOOL)lMinDistanceEnabled
{
	if((!self.bodyA || !self.bodyB) && self.isRunningInActiveScene)
	{
		[[AppDelegate appDelegate] modalDialogTitle:@"Assign Bodies" message:@"You must assign this joint to both BodyA and BodyB before editing the min distance"];
		return;
	}

	
    if(minDistanceEnabled != lMinDistanceEnabled)
    {
        minDistanceEnabled = lMinDistanceEnabled;
        
        minDistance = [self localLength];
    }
}


-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([CCBPhysicsPivotJoint nodeHasParent:self.bodyB parent:object] ||
	   [CCBPhysicsPivotJoint nodeHasParent:self.bodyA parent:object])
    {
        self.minDistance = self.minDistance;
        self.maxDistance = self.maxDistance;
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}


@end
