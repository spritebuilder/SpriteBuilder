#import <Foundation/Foundation.h>

@class SequencerHandler;

@interface AnimationPlaybackManager : NSObject

@property (nonatomic, weak) SequencerHandler *sequencerHandler;
@property (nonatomic) BOOL enabled;

- (IBAction)togglePlayback:(id)sender;

- (IBAction)toggleLoopingPlayback:(id)sender;

- (IBAction)playbackPlay:(id)sender;

- (IBAction)playbackStop:(id)sender;

- (IBAction)playbackJumpToStart:(id)sender;

- (IBAction)playbackStepBack:(id)sender;

- (IBAction)playbackStepForward:(id)sender;

- (IBAction)pressedPlaybackControl:(id)sender;

@end