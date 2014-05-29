#import <Foundation/Foundation.h>

@class SequencerHandler;

@interface AnimationPlaybackManager : NSObject

@property (nonatomic, weak) SequencerHandler *sequencerHandler;
@property (nonatomic) BOOL enabled;

- (IBAction)togglePlayback:(id)sender;

- (IBAction)toggleLoopingPlayback:(id)sender;

- (IBAction)play:(id)sender;

- (IBAction)stop;

- (IBAction)jumpToStart:(id)sender;

- (IBAction)stepOneFrameBack:(id)sender;

- (IBAction)stepOneFrameForward:(id)sender;

- (IBAction)pressedPlaybackControl:(id)sender;

@end