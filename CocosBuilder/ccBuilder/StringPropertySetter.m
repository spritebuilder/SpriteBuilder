//
//  StringPropertySetter.m
//  SpriteBuilder
//
//  Created by Viktor on 8/9/13.
//
//

#import "StringPropertySetter.h"
#import "NodeInfo.h"
#import "CCNode+NodeInfo.h"
#import "AppDelegate.h"
#import "LocalizationEditorHandler.h"

@implementation StringPropertySetter

+ (void) refreshStringProp:(NSString*)prop forNode:(CCNode*)node
{
    NSString* str = [StringPropertySetter stringForNode:node andProp:prop];
    BOOL localize = [StringPropertySetter isLocalizedNode:node andProp:prop];
    
    if (localize)
    {
        str = [[AppDelegate appDelegate].localizationEditorHandler translationForKey:str];
    }
    
    [node setValue:str forKey:prop];
}

+ (void) setString:(NSString*)str forNode:(CCNode*)node andProp:(NSString*)prop
{
    if (!str) str = @"";
    [node setExtraProp:str forKey:prop];
    [StringPropertySetter refreshStringProp:prop forNode:node];
}

+ (NSString*) stringForNode:(CCNode*)node andProp:(NSString*)prop
{
    NSString* str = [node extraPropForKey:prop];
    if (!str)
    {
        str = [node valueForKey:prop];
    }
    if (!str)
    {
        str = @"";
    }
    return str;
}

+ (void) setLocalized:(BOOL)localized forNode:(CCNode*)node andProp:(NSString*)prop
{
    [node setExtraProp: [NSNumber numberWithBool:localized] forKey:[prop stringByAppendingString:@"Localized"]];
    [StringPropertySetter refreshStringProp:prop forNode:node];
}

+ (BOOL) isLocalizedNode:(CCNode*)node andProp:(NSString*)prop
{
    return [[node extraPropForKey:[prop stringByAppendingString:@"Localized"]] boolValue];
}

+ (BOOL) hasTranslationForNode:(CCNode*)node andProp:(NSString*)prop
{
    NSString* str = [self stringForNode:node andProp:prop];
    return [[AppDelegate appDelegate].localizationEditorHandler hasTranslationForKey:str];
}

@end
