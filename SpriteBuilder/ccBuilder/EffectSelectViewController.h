//
//  EffectSelectViewController.h
//  SpriteBuilder
//
//  Created by John Twigg on 6/23/14.
//
//

#import <Cocoa/Cocoa.h>
#import "CCBModalSheetController.h"

@class EffectDescription;
@interface EffectSelectViewController : CCBModalSheetController <NSTableViewDataSource,NSTableViewDelegate>

@property (nonatomic) EffectDescription * selectedEffect;
@property (weak) IBOutlet NSTableView *tableView;



@end
