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

#import "AppDelegate.h"
#import "CocosScene.h"
#import "StringPropertySetter.h"

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
        LocalizationEditorLanguage* lang = [[LocalizationEditorLanguage alloc] initWithIsoLangCode:isoCode];
        [languages addObject:lang];
    }
    
    activeLanguages = [[NSMutableArray alloc] init];
    
    translations = [[NSMutableArray alloc] init];
    
    return self;
}

- (void) reset
{
    [translations removeAllObjects];
    [activeLanguages removeAllObjects];
    [windowController reload];
    windowController.hasOpenFile = NO;
}

- (void) store
{
    if (!managedFile) return;
    
    NSMutableDictionary* ser = [NSMutableDictionary dictionary];
    
    // Write header
    [ser setObject:@"SpriteBuilderTranslations" forKey:@"fileType"];
    [ser setObject:[NSNumber numberWithInt:kCCBTranslationFileFormatVersion] forKey:@"fileVersion"];
    
    // Languages
    NSMutableArray* serLangs = [NSMutableArray array];
    for (LocalizationEditorLanguage* lang in activeLanguages)
    {
        [serLangs addObject:lang.isoLangCode];
    }
    [ser setObject:serLangs forKey:@"activeLanguages"];
    
    // Translations
    NSMutableArray* serTransls = [NSMutableArray array];
    for (LocalizationEditorTranslation* transl in translations)
    {
        [serTransls addObject:[transl serialization]];
    }
    [ser setObject:serTransls forKey:@"translations"];
    
    // Store
    [ser writeToFile:managedFile atomically:YES];
    
    // Make sure that the scene is redrawn
    [StringPropertySetter refreshAllStringProps];
    [[CocosScene cocosScene] forceRedraw];
}

- (BOOL) load
{
    if (!managedFile) return NO;
    
    NSDictionary* ser = [NSDictionary dictionaryWithContentsOfFile:managedFile];
    
    // Validate file
    if (!ser) return NO;
    if (![[ser objectForKey:@"fileType"] isEqualToString:@"SpriteBuilderTranslations"]) return NO;
    if ([[ser objectForKey:@"fileVersion"] intValue] > kCCBTranslationFileFormatVersion) return NO;
    
    // Read data
    
    // Languages
    NSArray* serLangs = [ser objectForKey:@"activeLanguages"];
    for (NSString* isoCode in serLangs)
    {
        // Find language for code and add active language
        LocalizationEditorLanguage* lang = [self getLanguageByIsoLangCode:isoCode];
        if (lang) [activeLanguages addObject:lang];
    }
    
    // Translations
    NSArray* serTranslations = [ser objectForKey:@"translations"];
    for (id serTransl in serTranslations)
    {
        // Decode a translation and add it
        LocalizationEditorTranslation* transl = [[LocalizationEditorTranslation alloc] initWithSerialization:serTransl];
        if (transl) [translations addObject:transl];
    }
    
    [windowController reload];
    windowController.hasOpenFile = YES;
    
    return YES;
}

- (void) updateLanguageMenu
{
    [languageMenu removeAllItems];
    
    if (activeLanguages.count == 0)
    {
        NSMenuItem* item = [[NSMenuItem alloc] initWithTitle:@"No Languages Available" action:NULL keyEquivalent:@""];
        [item setEnabled:NO];
        [languageMenu addItem:item];
    }
    else
    {
        for (LocalizationEditorLanguage* lang in activeLanguages)
        {
            NSMenuItem* item = [[NSMenuItem alloc] initWithTitle:lang.name action:@selector(menuSetLanguage:) keyEquivalent:@""];
            item.target = self;
            
            if (lang == currentLanguage)
            {
                [item setState:NSOnState];
            }
            
            [languageMenu addItem:item];
        }
    }
}

- (NSString*) managedFile
{
    return managedFile;
}

- (void) setManagedFile:(NSString*) file
{
    if (file == managedFile) return;
    
    managedFile = [file copy];
    
    [self reset];
    
    if (file)
    {
        if ([[NSFileManager defaultManager] fileExistsAtPath:managedFile])
        {
            [self load];
        }
        else
        {
            [self store];
            windowController.hasOpenFile = YES;
        }
    }
    
    if (activeLanguages.count > 0)
    {
        [self setCurrentLanguage:[activeLanguages objectAtIndex:0]];
    }
    else
    {
        [self setCurrentLanguage:NULL];
    }
}

- (void) setEdited
{
    [[AppDelegate appDelegate] refreshPropertiesOfType:@"String"];
    [[AppDelegate appDelegate] refreshPropertiesOfType:@"Text"];
    
    [self store];
}

- (void) setCurrentLanguage:(LocalizationEditorLanguage*) lang
{
    LocalizationEditorLanguage* newLang = NULL;
    
    if ([activeLanguages containsObject:lang])
    {
        newLang = lang;
    }
    else if (activeLanguages.count > 0)
    {
        newLang = [activeLanguages objectAtIndex:0];
    }
    else
    {
        newLang = NULL;
    }
    
    if (newLang != currentLanguage)
    {
        currentLanguage = newLang;
        
        // Refresh file
        [StringPropertySetter refreshAllStringProps];
        [[CocosScene cocosScene] forceRedraw];
    }
    
    [self updateLanguageMenu];
}

- (void) menuSetLanguage:(id)sender
{
    NSString* name = [sender title];
    [self setCurrentLanguage:[self getLanguageByName:name]];
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

- (LocalizationEditorLanguage*) getLanguageByIsoLangCode:(NSString*)code
{
    for (LocalizationEditorLanguage* lang in languages)
    {
        if ([lang.isoLangCode isEqualToString:code]) return lang;
    }
    return NULL;
}

- (void) addActiveLanguage:(LocalizationEditorLanguage*) lang
{
    lang.quickEdit = YES;
    if ([activeLanguages containsObject:lang]) return;
    [activeLanguages addObject:lang];
    [self setCurrentLanguage:currentLanguage];
}

- (void) removeActiveLangage:(LocalizationEditorLanguage*) lang
{
    [activeLanguages removeObject:lang];
    
    for (LocalizationEditorTranslation* transl in self.translations)
    {
        [transl.translations removeObjectForKey:lang.isoLangCode];
    }
    [self setCurrentLanguage:currentLanguage];
}

- (IBAction)openEditor:(id)sender
{
    if (!windowController)
    {
        windowController = [[LocalizationEditorWindow alloc] initWithWindowNibName:@"LocalizationEditorWindow"];
    }
    [windowController.window makeKeyAndOrderFront:sender];
    windowController.hasOpenFile = (managedFile != NULL);
}

- (NSString*) translationForKey:(NSString*)key
{
    if (!key) return NULL;
    if (!currentLanguage) return key;
    
    for (LocalizationEditorTranslation* transl in translations)
    {
        if ([transl.key isEqualToString:key])
        {
            NSString* val = [transl.translations objectForKey:currentLanguage.isoLangCode];
            if (val)
            {
                return val;
            }
            else
            {
                return key;
            }
        }
    }
    return key;
}

- (BOOL) hasTranslationForKey:(NSString*)key
{
    if (!key) return NO;
    
    for (LocalizationEditorTranslation* transl in translations)
    {
        if ([transl.key isEqualToString:key]) return YES;
    }
    return NO;
}

- (void) createOrEditTranslationForKey:(NSString*)key
{
    if (![self hasTranslationForKey:key])
    {
        LocalizationEditorTranslation* transl = [[LocalizationEditorTranslation alloc] init];
        transl.key = key;
        [translations addObject:transl];
        [windowController reload];
        [self store];
    }
    
    int row = 0;
    for (LocalizationEditorTranslation* transl in translations)
    {
        if ([transl.key isEqualToString:key])
        {
            [windowController selectRow:row];
            break;
        }
        row++;
    }
}


@end
