//
//  EffectReflectionControl.m
//  SpriteBuilder
//
//  Created by John Twigg on 7/28/14.
//
//

#import "EffectReflectionControl.h"
#import "InspectorNodeReference.h"
#import "InspectorSpriteFrame.h"

@interface EffectReflectionControl ()
@property (weak) IBOutlet NSView *nodeReference;
@property (weak) IBOutlet NSView *normalMapSelectionView;
@end

@implementation EffectReflectionControl

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}

-(void)awakeFromNib
{
	[super awakeFromNib];
	
	{
		InspectorNodeReference* inspectorValue = [InspectorValue inspectorOfType:@"NodeReference" withSelection:(id)self.effect andPropertyName:@"environment" andDisplayName:@"" andExtra:nil];
		
		
		@try {
			// Load it's associated view
			// FIXME: fix deprecation warning
			SUPPRESS_DEPRECATED([NSBundle loadNibNamed:@"InspectorNodeReference" owner:inspectorValue]);
		}@catch (NSException * exception) {
			
			
		}
		
		inspectorValue.view.frame = CGRectMake(0, 0, self.nodeReference.frame.size.width, self.nodeReference.frame.size.height);
		inspectorValue.dragType = DragTypeEffectSprite;
		
		[self.nodeReference addSubview:inspectorValue.view];
		[inspectorValue willBeAdded];
	}
	
	{
		InspectorSpriteFrame* inspectorValue = [InspectorValue inspectorOfType:@"SpriteFrame" withSelection:(id)self.effect andPropertyName:@"normalMap" andDisplayName:@"" andExtra:nil];
		
		
		@try {
			// Load it's associated view
			// FIXME: fix deprecation warning
			SUPPRESS_DEPRECATED([NSBundle loadNibNamed:@"InspectorSpriteFrame" owner:inspectorValue]);
		}@catch (NSException * exception) {
			
			
		}
		
		//inspectorValue.view.frame = CGRectMake(0, 0, self.normalMapSelectionView.frame.size.width, self.normalMapSelectionView.frame.size.height);
		
		[self.normalMapSelectionView addSubview:inspectorValue.view];
		[inspectorValue willBeAdded];
		
	}
	
	
	
}
@end

