//
//  LocalizationEditorLanguage.m
//  SpriteBuilder
//
//  Created by Viktor on 8/7/13.
//
//

#import "LocalizationEditorLanguage.h"

@implementation LocalizationEditorLanguage

- (id) initWithIsoLangCode:(NSString*)code
{
    self = [super init];
    if (!self) return NULL;
    
    self.isoLangCode = code;
    
    if ([code isEqualToString:@"vn"])
    {
        self.name = @"Vietnamese";
    }
    else if ([code isEqualToString:@"zh-Hans"])
    {
        self.name = @"Simplified Chinese";
    }
    else if ([code isEqualToString:@"zh-Hant"])
    {
        self.name = @"Traditional Chinese";
    }
    else
    {
        NSLocale* enLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en"];
        self.name = [enLocale displayNameForKey:NSLocaleLanguageCode value:code];
    }
    
    self.name = [NSString stringWithFormat:@"%@ (%@)", self.name, code];
    
    self.quickEdit = YES;
    
    return self;
}

+ (NSString*) nameFromCode:(NSString*)code
{
    NSString* name = NULL;
    
    if ([code isEqualToString:@"vn"])
    {
        name = @"Vietnamese";
    }
    else if ([code isEqualToString:@"zh-Hans"])
    {
        name = @"Simplified Chinese";
    }
    else if ([code isEqualToString:@"zh-Hant"])
    {
        name = @"Traditional Chinese";
    }
    else
    {
        NSLocale* enLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en"];
        name = [enLocale displayNameForKey:NSLocaleLanguageCode value:code];
    }
    
    name = [NSString stringWithFormat:@"%@ (%@)", name, code];
    
    return name;
}

/*
 * Implemented in order to allow these languages to populate a mutable dictionary with
 * the setObject:forKey: method
 */
-(id)copyWithZone:(NSZone *)zone{
    LocalizationEditorLanguage* newLang = [[[self class] allocWithZone:zone] init];
    newLang->_isoLangCode = _isoLangCode;
    newLang->_name = _name;
    newLang->_quickEdit = _quickEdit;
    return newLang;
}

/*
 * The two functions below were reimplemented in order to make comparing languages
 * easier since we're only going to care if their name is the same.
 */
-(BOOL)isEqual:(id)object{
    if([((LocalizationEditorLanguage *) object).name isEqualToString:self.name]){
        return YES;
    }
    return NO;
}
- (NSUInteger)hash
{
    return [_name hash];
}

@end
