//
//  LocalizationEditorTranslation.m
//  SpriteBuilder
//
//  Created by Viktor on 8/7/13.
//
//

#import "LocalizationEditorTranslation.h"
#import "LocalizationEditorLanguage.h"

@implementation LocalizationEditorTranslation

@synthesize translations = _translations;

- (id) init
{
    self = [super init];
    if (!self) return NULL;
    
    _translations = [[NSMutableDictionary alloc] init];
    
    return self;
}

- (BOOL) hasTranslationsForLanguages:(NSArray*)languages
{
    for (LocalizationEditorLanguage* lang in languages)
    {
        NSString* transl = [_translations objectForKey:lang.isoLangCode];
        if (!transl) return NO;
        if ([transl isEqualToString:@""]) return NO;
    }
    
    return YES;
}

@end
