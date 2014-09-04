//
//  EffectGlassControl.m
//  SpriteBuilder
//
//  Created by John Twigg on 7/28/14.
//
//

#import "EffectGlassControl.h"
#import "InspectorNodeReference.h"
#import "InspectorSpriteFrame.h"

@interface EffectGlassControl()
@property (weak) IBOutlet NSView *reflectionEnvironmentView;
@property (weak) IBOutlet NSView *refractionEnvironmentView;
@property (weak) IBOutlet NSView *normalMapSelectionView;
@end

@implementation EffectGlassControl

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
		InspectorNodeReference* inspectorValue = [InspectorValue inspectorOfType:@"NodeReference" withSelection:(id)self.effect andPropertyName:@"reflectionEnvironment" andDisplayName:@"" andExtra:nil];
		
		
		@try {
			// Load it's associated view
			// FIXME: fix deprecation warning
			SUPPRESS_DEPRECATED([NSBundle loadNibNamed:@"InspectorNodeReference" owner:inspectorValue]);
		}@catch (NSException * exception) {
			
			
		}
		
		inspectorValue.view.frame = CGRectMake(0, 0,
											   self.reflectionEnvironmentView.frame.size.width,
											   self.reflectionEnvironmentView.frame.size.height);
		inspectorValue.dragType = DragTypeEffectSprite;
		
		[self.reflectionEnvironmentView addSubview:inspectorValue.view];
		[inspectorValue willBeAdded];
	}
	
	{
		InspectorNodeReference* inspectorValue = [InspectorValue inspectorOfType:@"NodeReference" withSelection:(id)self.effect andPropertyName:@"refractionEnvironment" andDisplayName:@"" andExtra:nil];
		
		
		@try {
			// Load it's associated view
			// FIXME: fix deprecation warning
			SUPPRESS_DEPRECATED([NSBundle loadNibNamed:@"InspectorNodeReference" owner:inspectorValue]);
		}@catch (NSException * exception) {
			
			
		}
		
		inspectorValue.view.frame = CGRectMake(0, 0,
											   self.refractionEnvironmentView.frame.size.width,
											   self.refractionEnvironmentView.frame.size.height);
		inspectorValue.dragType = DragTypeEffectSprite;
		
		[self.refractionEnvironmentView addSubview:inspectorValue.view];
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
		
		[self.normalMapSelectionView addSubview:inspectorValue.view];
		[inspectorValue willBeAdded];
		
	}
	
	
	
}
@end
