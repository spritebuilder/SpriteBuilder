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


@end
