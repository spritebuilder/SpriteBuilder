//
//  LocalizationTranslateWindowView.m
//  SpriteBuilder
//
//  Created by Benjamin Koatz on 6/23/14.
//
//

#import "LocalizationTranslateWindowHandler.h"


@implementation LocalizationTranslateWindowHandler
-(void)setPopOver:(NSPopover*)p button:(NSButton*)b{
    
    self.translateButton = b;
    self.translatePopOver = p;

}
-(void)mouseUp:(NSEvent *)theEvent{
    [super mouseUp:theEvent];
    if([self.translatePopOver isShown]){
        [self.translatePopOver close];
    }
    self.translateButton.intValue = 0;
}

-(id)copyWithZone:(NSZone *)zone{
    LocalizationTranslateWindowHandler* newHandler = [[[self class] allocWithZone:zone] init];
    newHandler->_translatePopOver = _translatePopOver;
    return newHandler;
}

-(void)close{
    if([self isModalPanel]){
        [NSApp endSheet:self];
        [self orderOut:nil];
    }
}
@end
