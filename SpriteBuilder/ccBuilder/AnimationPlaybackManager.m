#import "AnimationPlaybackManager.h"

#import "SequencerHandler.h"
#import "SequencerSequence.h"
#import "NotificationNames.h"


@interface AnimationPlaybackManager ()

@property (nonatomic) BOOL playingBack;
@property (nonatomic) double playbackLastFrameTime;

@end


@implementation AnimationPlaybackManager

- (void)updatePlayback
{
    if (!_enabled)
    {
        [self stop];
    }

    if (_playingBack)
    {
        // Step forward
        double thisTime = [NSDate timeIntervalSinceReferenceDate];
        double deltaTime = thisTime - _playbackLastFrameTime;
        double frameDelta = 1.0 / _sequencerHandler.currentSequence.timelineResolution;
        double targetNewTime = _sequencerHandler.currentSequence.timelinePosition + deltaTime;

        int steps = (int) (deltaTime / frameDelta);

        //determine new time in to the future.
        [_sequencerHandler.currentSequence stepForward:steps];

        if (_sequencerHandler.currentSequence.timelinePosition >= _sequencerHandler.currentSequence.timelineLength)
        {
            //If we loop, calulate the overhang
            if (targetNewTime >= _sequencerHandler.currentSequence.timelinePosition && _sequencerHandler.loopPlayback)
            {
                [self jumpToStart:nil];
                steps = (int) ((targetNewTime - _sequencerHandler.currentSequence.timelineLength) / frameDelta);
                [_sequencerHandler.currentSequence stepForward:steps];
            }
            else
            {
                [self stop];
                return;
            }
        }

        self.playbackLastFrameTime += steps * frameDelta;

        // Call this method again in a little while
        [self performSelector:@selector(updatePlayback) withObject:nil afterDelay:frameDelta];
    }
}

- (IBAction)togglePlayback:(id)sender
{
    if (!_playingBack)
    {
        [self play:sender];
    }
    else
    {
        [self stop];
    }
}

- (IBAction)toggleLoopingPlayback:(id)sender
{
    _sequencerHandler.loopPlayback = [(NSButton *) sender state] == 1;
}

- (IBAction)play:(id)sender
{
    if (!_enabled
        || _playingBack)
    {
        return;
    }

    // Jump to start of sequence if the end is reached
    if (_sequencerHandler.currentSequence.timelinePosition >= _sequencerHandler.currentSequence.timelineLength)
    {
        _sequencerHandler.currentSequence.timelinePosition = 0;
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:ANIMATION_PLAYBACK_WILL_START object:nil];

    // Start playback
    self.playbackLastFrameTime = [NSDate timeIntervalSinceReferenceDate];
    self.playingBack = YES;
    [self updatePlayback];
}

- (IBAction)stop
{
    self.playingBack = NO;
}

- (IBAction)jumpToStart:(id)sender
{
    if (!_enabled)
    {
        return;
    }

    _playbackLastFrameTime = [NSDate timeIntervalSinceReferenceDate];
    _sequencerHandler.currentSequence.timelinePosition = 0;
    [[SequencerHandler sharedHandler] updateScrollerToShowCurrentTime];
}

- (IBAction)stepOneFrameBack:(id)sender
{
    if (!_enabled)
    {
        return;
    }

    [_sequencerHandler.currentSequence stepBack:1];
}

- (IBAction)stepOneFrameForward:(id)sender
{
    if (!_enabled)
    {
        return;
    }

    [_sequencerHandler.currentSequence stepForward:1];
}

- (IBAction)pressedPlaybackControl:(id)sender
{
    NSSegmentedControl *sc = sender;

    int tag = [sc selectedSegment];
    switch (tag)
    {
        case 0:
            [self jumpToStart:sender];
            break;
        case 1:
            [self stepOneFrameBack:sender];
            break;
        case 2:
            [self stepOneFrameForward:sender];
            break;
        case 3:
            [self stop];
            break;
        case 4:
            [self play:sender];
            break;

        default:
            NSLog(@"Segmented control's button tag out of bounds!");
    }
}


@end