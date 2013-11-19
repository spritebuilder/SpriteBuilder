//
//  SequenerButtonCell.m
//  SpriteBuilder
//
//  Created by John Twigg on 2013-11-18.
//
//

#import "SequencerButtonCell.h"
#import "SequencerHandler.h"

@implementation SequencerButtonCell
@synthesize node;

- (void) drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    if (!imagesLoaded)
    {
        imgRowBgChannel = [[NSImage imageNamed:@"seq-row-channel-bg.png"] retain];
        imagesLoaded = YES;
    }
    
    if (!node)
    {
        NSRect rowRect = NSMakeRect(cellFrame.origin.x, cellFrame.origin.y, cellFrame.size.width+16, kCCBSeqDefaultRowHeight);
        [imgRowBgChannel drawInRect:rowRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
        return;
    }

    [super drawWithFrame:cellFrame inView:controlView];
}
@end
