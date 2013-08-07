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
        self.name = @"Chinese (Simplified)";
    }
    else if ([code isEqualToString:@"zh-Hant"])
    {
        self.name = @"Chinese (Traditional)";
    }
    else
    {
        NSLocale* enLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en"] autorelease];
        self.name = [enLocale displayNameForKey:NSLocaleLanguageCode value:code];
    }
    
    self.quickEdit = YES;
    
    return self;
}

- (void) dealloc
{
    self.isoLangCode = NULL;
    self.name = NULL;
    
    [super dealloc];
}

@end
