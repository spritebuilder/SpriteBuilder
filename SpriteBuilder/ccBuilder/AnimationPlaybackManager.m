#import "AnimationPlaybackManager.h"

#import "SequencerHandler.h"
#import "SequencerSequence.h"


@interface AnimationPlaybackManager ()

@property (nonatomic) BOOL playingBack;
@property (nonatomic) double playbackLastFrameTime;

@end


@implementation AnimationPlaybackManager

- (void)updatePlayback
{
    if (!_enabled)
    {
        [self playbackStop:NULL];
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
                [self playbackJumpToStart:nil];
                steps = (int) ((targetNewTime - _sequencerHandler.currentSequence.timelineLength) / frameDelta);
                [_sequencerHandler.currentSequence stepForward:steps];
            }
            else
            {
                [self playbackStop:NULL];
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
        [self playbackPlay:sender];
    }
    else
    {
        [self playbackStop:sender];
    }
}

- (IBAction)toggleLoopingPlayback:(id)sender
{
    _sequencerHandler.loopPlayback = [(NSButton *) sender state] == 1;
}

- (IBAction)playbackPlay:(id)sender
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

    // TODO Deselect all objects to improve performance
    //self.selectedNodes = NULL;

    // Start playback
    self.playbackLastFrameTime = [NSDate timeIntervalSinceReferenceDate];
    self.playingBack = YES;
    [self updatePlayback];
}

- (IBAction)playbackStop:(id)sender
{
    self.playingBack = NO;
}

- (IBAction)playbackJumpToStart:(id)sender
{
    if (!_enabled)
    {
        return;
    }

    _playbackLastFrameTime = [NSDate timeIntervalSinceReferenceDate];
    _sequencerHandler.currentSequence.timelinePosition = 0;
    [[SequencerHandler sharedHandler] updateScrollerToShowCurrentTime];
}

- (IBAction)playbackStepBack:(id)sender
{
    if (!_enabled)
    {
        return;
    }

    [_sequencerHandler.currentSequence stepBack:1];
}

- (IBAction)playbackStepForward:(id)sender
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
        case 0: [self playbackJumpToStart:sender];
            break;
        case 1: [self playbackStepBack:sender];
            break;
        case 2: [self playbackStepForward:sender];
            break;
        case 3: [self playbackStop:sender];
            break;
        case 4: [self playbackPlay:sender];
            break;

        default:
            NSLog(@"Segmented control's button tag out of bounds!");
    }
}


@end