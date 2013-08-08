//
//  LocalizationEditorHandler.m
//  SpriteBuilder
//
//  Created by Viktor on 8/6/13.
//
//

#import "LocalizationEditorHandler.h"
#import "LocalizationEditorWindow.h"
#import "LocalizationEditorLanguage.h"
#import "LocalizationEditorTranslation.h"

@implementation LocalizationEditorHandler

@synthesize languages;
@synthesize activeLanguages;
@synthesize translations;
@synthesize windowController;

- (id) init
{
    self = [super init];
    if (!self) return NULL;
    
    // Load supported languages
    NSArray* isoCodes = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"LocaliztaionEditorLanguageList" ofType:@"plist"]];
    
    languages = [[NSMutableArray alloc] init];
    for (NSString* isoCode in isoCodes)
    {
        LocalizationEditorLanguage* lang = [[[LocalizationEditorLanguage alloc] initWithIsoLangCode:isoCode] autorelease];
        [languages addObject:lang];
    }
    
    activeLanguages = [[NSMutableArray alloc] init];
    
    translations = [[NSMutableArray alloc] init];
    
    return self;
}

- (BOOL) isValidKey:(NSString*) key forTranslation:(LocalizationEditorTranslation*) transl
{
    if (!key) return NO; // Missing key
    if ([key isEqualToString:@""]) return NO; // Missing key
    
    for (LocalizationEditorTranslation* cTransl in self.translations)
    {
        if (cTransl == transl) continue;
        if ([cTransl.key isEqualToString:key]) return NO; // Duplicate entry
    }
    return YES;
}

- (LocalizationEditorLanguage*) getLanguageByName:(NSString*)name
{
    for (LocalizationEditorLanguage* lang in languages)
    {
        if ([lang.name isEqualToString:name]) return lang;
    }
    return NULL;
}

- (void) addActiveLanguage:(LocalizationEditorLanguage*) lang
{
    lang.quickEdit = YES;
    if ([activeLanguages containsObject:lang]) return;
    [activeLanguages addObject:lang];
}

- (void) removeActiveLangage:(LocalizationEditorLanguage*) lang
{
    [activeLanguages removeObject:lang];
    
    for (LocalizationEditorTranslation* transl in self.translations)
    {
        [transl.translations removeObjectForKey:lang.isoLangCode];
    }
}

- (IBAction)openEditor:(id)sender
{
    if (!windowController)
    {
        windowController = [[LocalizationEditorWindow alloc] initWithWindowNibName:@"LocalizationEditorWindow"];
    }
    [windowController.window makeKeyAndOrderFront:sender];
}

- (void) dealloc
{
    [languages release];
    [activeLanguages release];
    [windowController release];
    [translations release];
    [super dealloc];
}

@end
