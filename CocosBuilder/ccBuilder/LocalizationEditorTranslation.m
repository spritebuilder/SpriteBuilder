//
//  LocalizationEditorTranslation.m
//  SpriteBuilder
//
//  Created by Viktor on 8/7/13.
//
//

#import "LocalizationEditorTranslation.h"

@implementation LocalizationEditorTranslation

@synthesize translations = _translations;

- (id) init
{
    self = [super init];
    if (!self) return NULL;
    
    _translations = [[NSMutableDictionary alloc] init];
    
    return self;
}

@end
