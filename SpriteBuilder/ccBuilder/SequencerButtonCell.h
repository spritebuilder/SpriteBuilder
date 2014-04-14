//
//  SequenerButtonCell.h
//  SpriteBuilder
//
//  Created by John Twigg on 2013-11-18.
//
//

#import <Cocoa/Cocoa.h>
#import "cocos2d.h"

@interface SequencerButtonCell : NSButtonCell
{
    NSImage * imgRowBgChannel;
    BOOL      imagesLoaded;
    
    CCNode * __weak node;
    
}

@property (nonatomic,weak) CCNode* node;
@end


typedef enum
{
    LockedButtonStatus_Set,
    LockedButtonStatus_SetNotEnabled,
    LockedButtonStatus_NoSet,
} LockedButtonStatus;

@interface SequencerLockedCell : SequencerButtonCell
@property (nonatomic) LockedButtonStatus status;
@end

@interface SequencerHiddenCell : SequencerButtonCell
@end

