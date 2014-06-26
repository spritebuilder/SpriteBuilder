//
//  LocalizationTranslateWindowView.h
//  SpriteBuilder
//
//  Created by Benjamin Koatz on 6/23/14.
//
//

#import <Foundation/Foundation.h>

@interface LocalizationTranslateWindowHandler : NSWindow
@property (nonatomic,strong) NSPopover* translatePopOver;
@property (nonatomic,strong) NSButton* translateButton;
-(void)setPopOver:(NSPopover*)p button:(NSButton*)b;

@end