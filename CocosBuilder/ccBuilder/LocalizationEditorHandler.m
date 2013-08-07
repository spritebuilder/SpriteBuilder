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

@implementation LocalizationEditorHandler

@synthesize languages;

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
    
    return self;
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
    [windowController release];
    [super dealloc];
}

@end
