//
//  CCBPPhysicsSpringJoint.m
//  SpriteBuilder
//
//  Created by John Twigg
//
//

#import "CCBPhysicsSpringJoint.h"
#import "AppDelegate.h"

@interface CCBPhysicsJoint()
-(void)updateSelectionUI;
@end

@implementation CCBPhysicsSpringJoint
{
    CCNode          * springNode;
    
    int               springPointsCount;
    float               bodyLength;

    CCSprite        * restLengthHandle;
    CCSprite9Slice  * restLengthHandleBody;

}


- (id) init
{
    self = [super init];
    if (self)
    {
        self.stiffness = 4.0f;
        self.damping = 1.0f;
        self.restLength = [self localLength];
    }
    
    return self;
}


-(void)setupBody
{
    CCSizeType sizeType;
    sizeType.heightUnit = CCSizeUnitUIPoints;
    sizeType.widthUnit = CCSizeUnitUIPoints;
    
    
    springNode = [CCNode node];
    springNode.scaleType = CCScaleTypeScaled;
    [scaleFreeNode addChild:springNode];
    
    [super setupBody];
    
    restLengthHandle = [CCSprite spriteWithImageNamed:@"joint-distance-handle-short.png"];
    restLengthHandle.anchorPoint = ccp(0.5f, 0.0f);
    [scaleFreeNode addChild:restLengthHandle];
 
    restLengthHandleBody = [CCSprite9Slice spriteWithImageNamed:@"joint-distance-slide.png"];
    restLengthHandleBody.marginLeft = 0.0f;
    restLengthHandleBody.marginRight = kMargin;
    restLengthHandleBody.marginBottom = 0.0;
    restLengthHandleBody.marginTop = 0.0;
    restLengthHandleBody.scale = 1.0;
    restLengthHandleBody.anchorPoint = ccp(0.0f,0.5f);

    restLengthHandleBody.contentSizeType = sizeType;
    [scaleFreeNode addChild:restLengthHandleBody];
    
}

-(void)updateRenderBody
{
    [super updateRenderBody];
    float length = [self worldLength];
    
    
    restLengthHandle.position = ccpMult(ccp(length *  self.restLength / [self localLength], kEdgeRadius - 1.0f),1/[CCDirector sharedDirector].contentScaleFactor);
    
    restLengthHandleBody.contentSize = CGSizeMake(length *  self.restLength / [self localLength] + kEdgeRadius, kEdgeRadius * 2.0f);
    
    [self updateSprintBody];
   
}



const int kSpringHeight = 8;
const int kSpringHeightHalf = kSpringHeight/2;


-(void)updateSprintBody
{
    float currentBodyLength = [self worldLength];
    if(bodyLength != currentBodyLength)
    {
        [springNode removeAllChildrenWithCleanup:YES];
        bodyLength = currentBodyLength;
        
        if((int)bodyLength == 0)
            return;

        //How many full zig-zags can we produce.
        int wholeCounts = (bodyLength - kSpringHeight) / kSpringHeightHalf;
        if(wholeCounts % 2 == 0) //Make sure its odd
            wholeCounts--;


        float remainder = -1.0f;
        float padding = kSpringHeightHalf;
        float scale = 1.0f;
        
        
        if(wholeCounts > 1) //case when there's lots of room.
            remainder   = bodyLength - wholeCounts * kSpringHeightHalf - kSpringHeight;
        else
        {
            
            float remainingSpace = bodyLength - kSpringHeightHalf * 3;

            wholeCounts = 3;
            remainder = 0;
            if(remainingSpace > 0)
            {
                padding = remainingSpace/2;
            }
            else
            {
                //We're really cramped. Start scaling down.
                padding = 0;
                scale = bodyLength/(kSpringHeightHalf * 3);
            }
        }
        
        CGPoint * pt = malloc(sizeof(CGPoint) * (wholeCounts + 7));
        float sign = ((wholeCounts + 1)/2) %2 == 0 ? 1.0f : -1.0f; //Crazy sign calc that, something like wholeCount=[1,5,9...] sign==-1, else wholeCount[3,7,11...] sgn = 1. Or vice versa...  doesn't matter.
        
        //padding straight line at the start
        pt[0] = ccp(0,0); //start
        pt[1] = ccp(padding,0); //padding.
        pt[2] = ccp(remainder/4.0f + padding, -sign * remainder/2);
        pt[3] = ccp(remainder/2.0f + padding, 0);
        pt[4] = ccp(pt[3].x + kSpringHeightHalf/2,sign * kSpringHeightHalf);
        


        float offset = pt[4].x + kSpringHeightHalf;
       
        //Draw the zig-zag
        for(int i = 0; i < wholeCounts -1; i++)
        {
            pt[i+ 5] = ccp(offset + i * kSpringHeightHalf, -sign * kSpringHeightHalf);
            sign *= -1.0f;
        }
        
        //Close out the spring with a straight line.
        pt[wholeCounts +4] = ccp(bodyLength/scale - pt[2].x, pt[2].y);
        pt[wholeCounts +5] = ccp(bodyLength/scale -  pt[1].x, 0);
        pt[wholeCounts +6] = ccp(bodyLength/scale, 0);
        
        
        //////        //////        //////        //////
        //The big draw call.
        CCColor * whiteColor = [CCColor colorWithWhite:1.0f alpha:0.25f];
        CCColor * blackColor = [CCColor colorWithWhite:0.0f alpha:0.75f];
        for(int i = 1; i < wholeCounts + 7; i++)
        {
            CCDrawNode * draw = [CCDrawNode node];
			[draw drawSegmentFrom:ccpMult(ccpAdd(pt[i-1],ccp(1.0f,0.0f)),scale) to:ccpMult(ccpAdd(pt[i],ccp(1.0f,0.0f)),scale) radius:1.0f color:blackColor];
			[springNode addChild:draw];

			draw = [CCDrawNode node];
            [draw drawSegmentFrom:ccpMult(pt[i-1],scale) to:ccpMult(pt[i],scale) radius:1.0f color:whiteColor];
			[springNode addChild:draw];
			
        }
        
        free(pt);
        
    }
}





-(JointHandleType)hitTestJointHandle:(CGPoint)worlPos
{
    {
        CGPoint pointMin = [restLengthHandle convertToNodeSpaceAR:worlPos];
        pointMin = ccpSub(pointMin, ccp(0,7.0f));
        if(ccpLength(pointMin) < 7.0f)
        {
            return RestLengthHandle;
        }
    }
    
    return [super hitTestJointHandle:worlPos];;
}

-(void)updateSelectionUI
{
    //If selected, display selected sprites.
    if(selectedBodyHandle & (1 << EntireJoint) && _restLengthEnabled && (self.bodyA && self.bodyB))
    {
		
        if(restLengthHandle.parent == nil)
            [scaleFreeNode addChild:restLengthHandle];
		
		if(restLengthHandleBody.parent == nil)
			[scaleFreeNode addChild:restLengthHandleBody];
    }
    else //Unseleted
    {
        if(restLengthHandle.parent != nil)
            [restLengthHandle removeFromParentAndCleanup:NO];
		
		if(restLengthHandleBody.parent != nil)
			[restLengthHandleBody removeFromParentAndCleanup:NO];
    }
	
	
    
    
    if(selectedBodyHandle & (1 << RestLengthHandle))
    {
        restLengthHandleBody.spriteFrame = [self frameWithImageNamed:@"joint-distance-slide-sel.png"];
    }
    else
    {
        restLengthHandleBody.spriteFrame = [self frameWithImageNamed:@"joint-distance-slide.png"];
    }
    
    [super updateSelectionUI];
}



#pragma mark - Properties -


-(void)setAnchorA:(CGPoint)lAnchorA
{
    [super setAnchorA:lAnchorA];
    //refresh max mins
    self.restLength = self.restLength;
    
}


-(void)setAnchorB:(CGPoint)lAnchorB
{
    [super setAnchorB:lAnchorB];
    //refresh max mins
    self.restLength = self.restLength;
}



-(void)setBodyHandle:(CGPoint)worldPos bodyType:(JointHandleType)bodyType
{
    if(bodyType == RestLengthHandle)
    {
        CGPoint localPoint = [self convertToNodeSpace:worldPos];
        self.restLength =  localPoint.x;
        [[AppDelegate appDelegate] refreshProperty:@"restLength"];
    }
    
    [super setBodyHandle:worldPos bodyType:bodyType];
}

-(void)setBodyA:(CCNode *)lBodyA
{

    bool change = NO;
    if(bodyA && bodyA != lBodyA)
    {
        change = YES;
    }
    
    [super setBodyA:lBodyA];
    
    if(change)
    {
        self.restLength = self.restLength;
        [[AppDelegate appDelegate] refreshProperty:@"restLength"];
    }
}

-(void)setBodyB:(CCNode *)lBodyB
{
    bool change = NO;
    if(bodyB && bodyB != lBodyB)
    {
        change = YES;
    }
    
    [super setBodyB:lBodyB];

    
    if(change)
    {
        self.restLength = self.restLength;
        [[AppDelegate appDelegate] refreshProperty:@"restLength"];
    }
}

-(void)setRestLength:(float)restLength
{
    _restLength = restLength;
	
	if(!_restLengthEnabled)
	{
		_restLength = [self localLength];
	}
	else if(_restLength < 0)
	{
		_restLength = 0;
	}
		
	[[AppDelegate appDelegate] refreshProperty:@"restLength"];
}

-(void)setRestLengthEnabled:(BOOL)restLengthEnabled
{
	if((!self.bodyA || !self.bodyB) && self.isRunningInActiveScene)
	{
		[[AppDelegate appDelegate] modalDialogTitle:@"Assign Bodies" message:@"You must assign this joint to both BodyA and BodyB before editing the rest length"];
		return;
	}
	
	_restLengthEnabled = restLengthEnabled;
	self.restLength = self.restLength;
	
}

-(void)setStiffness:(float)stiffness
{
	if(stiffness < 0)
	{
		[[AppDelegate appDelegate] modalDialogTitle:@"Stiffness Restrictions" message:@"The spring stiffness must be greater than Zero"];
		[[AppDelegate appDelegate] performSelector:@selector(refreshProperty:) withObject:@"stiffness" afterDelay:0];
		return;
	}
	
	_stiffness = stiffness;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	
	self.restLength = self.restLength;
	
	[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}




@end
