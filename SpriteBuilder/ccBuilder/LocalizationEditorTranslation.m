//
//  LocalizationEditorTranslation.m
//  SpriteBuilder
//
//  Created by Viktor on 8/7/13.
//
//

#import "LocalizationEditorTranslation.h"
#import "LocalizationEditorLanguage.h"
#import "PasteboardTypes.h"

@implementation LocalizationEditorTranslation

@synthesize translations = _translations;

- (id) init
{
    self = [super init];
    if (!self) return NULL;
    
    _translations = [[NSMutableDictionary alloc] init];
    
    return self;
}

- (id) initWithSerialization:(id)ser
{
    self = [super init];
    if (!self) return NULL;
    
    NSDictionary* dict = ser;
    
    self.key = [dict objectForKey:@"key"];
    self.comment = [dict objectForKey:@"comment"];
    _translations = [[dict objectForKey:@"translations"] mutableCopy];
    
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

- (id) serialization
{
    NSMutableDictionary* ser = [NSMutableDictionary dictionary];
    
    if (self.key) [ser setObject:self.key forKey:@"key"];
    if (self.comment) [ser setObject:self.comment forKey:@"comment"];
    [ser setObject:self.translations forKey:@"translations"];
    
    return ser;
}

#pragma mark Writing to paste board

- (id) pasteboardPropertyListForType:(NSString *)type
{
    if ([type isEqualToString:PASTEBOARD_TYPE_LOCALIZATIONEDITORTRANSLATION])
    {
        return [self serialization];
    }
    return NULL;
}

- (NSArray *)writableTypesForPasteboard:(NSPasteboard *)pasteboard
{
    return @[PASTEBOARD_TYPE_LOCALIZATIONEDITORTRANSLATION];
}

- (NSPasteboardWritingOptions)writingOptionsForType:(NSString *)type pasteboard:(NSPasteboard *)pasteboard
{
    if ([type isEqualToString:PASTEBOARD_TYPE_LOCALIZATIONEDITORTRANSLATION])
    {
        return NSPasteboardWritingPromised;
    }
    return 0;
}

@end
