//
//  LocalizationTranslateWindowView.m
//  SpriteBuilder
//
//  Created by Benjamin Koatz on 6/23/14.
//
//

#import "LocalizationTranslateWindowHandler.h"


@implementation LocalizationTranslateWindowHandler

-(void)close{
    if([self isModalPanel]){
        [NSApp endSheet:self];
        [self orderOut:nil];
    }
}
@end
