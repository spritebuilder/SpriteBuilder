//
//  SequenerButtonCell.m
//  SpriteBuilder
//
//  Created by John Twigg on 2013-11-18.
//
//

#import "SequencerButtonCell.h"
#import "SequencerHandler.h"
#import "CCNode+NodeInfo.h"
#import "PlugInNode.h"

@implementation SequencerButtonCell
@synthesize node;

- (void) drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    if (!imagesLoaded)
    {
        imgRowBgChannel = [NSImage imageNamed:@"seq-row-channel-bg.png"];
        imagesLoaded = YES;
    }
    
    //Drag background if requires thick row.
    if (!node )
    {
        NSRect rowRect = NSMakeRect(cellFrame.origin.x, cellFrame.origin.y + cellFrame.size.height - kCCBSeqDefaultRowHeight, cellFrame.size.width+16, kCCBSeqDefaultRowHeight);
        [imgRowBgChannel drawInRect:rowRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
        return;
    }

    [super drawWithFrame:cellFrame inView:controlView];
}

@end

@implementation SequencerHiddenCell

-(void)setEnabled:(BOOL)flag
{
    [super setEnabled:flag];
    
    if(![self isEnabled])
    {
        self.image = [NSImage imageNamed:@"seq-visible-faint.png"];
    }
    else
    {
        self.image = [NSImage imageNamed:@"seq-visible.png"];
    }
}

@end

@implementation SequencerLockedCell

-(void)setStatus:(LockedButtonStatus)status
{
    _status = status;
    
    switch (_status) {
        case LockedButtonStatus_Set:
        {
            self.image = [NSImage imageNamed:@"seq-locked.png"];
        }
        break;
        case LockedButtonStatus_NoSet:
        {
            self.image =  [NSImage imageNamed:@"seq-notset.png"];
        }
            break;
        case LockedButtonStatus_SetNotEnabled:
        {
            self.image =  [NSImage imageNamed:@"seq-locked-faint.png"];
        }
            break;
        default:
            break;
    }
  

}

@end

