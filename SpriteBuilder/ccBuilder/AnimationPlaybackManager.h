#import <Foundation/Foundation.h>

@class SequencerHandler;
@class CCBDocument;

@interface AnimationPlaybackManager : NSObject


@property (nonatomic, weak) SequencerHandler *sequencerHandler;

// TODO: make this manager enable-able
@property (nonatomic, weak) CCBDocument *currentDocument;
@property (nonatomic) BOOL hasOpenedDocument;


- (IBAction)togglePlayback:(id)sender;

- (IBAction)toggleLoopingPlayback:(id)sender;

- (IBAction)playbackPlay:(id)sender;

- (IBAction)playbackStop:(id)sender;

- (IBAction)playbackJumpToStart:(id)sender;

- (IBAction)playbackStepBack:(id)sender;

- (IBAction)playbackStepForward:(id)sender;

- (IBAction)pressedPlaybackControl:(id)sender;

@end