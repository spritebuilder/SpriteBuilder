//
//  LocalizationEditorWindow.m
//  SpriteBuilder
//
//  Created by Viktor on 8/6/13.
//
//

#import "LocalizationEditorWindow.h"
#import "LocalizationEditorLanguage.h"
#import "LocalizationEditorHandler.h"
#import "AppDelegate.h"

@implementation LocalizationEditorWindow

- (void) populateLanguageAddMenu
{
    NSArray* langs = [AppDelegate appDelegate].localizationEditorHandler.languages;
    
    NSMutableArray* langTitles = [NSMutableArray array];
    for (LocalizationEditorLanguage* lang in langs)
    {
        [langTitles addObject:lang.name];
    }
    [popLanguageAdd addItemsWithTitles:langTitles];
}

- (void) awakeFromNib
{
    [self populateLanguageAddMenu];
}

- (IBAction)pressedAdd:(id)sender
{}

- (IBAction)pressedRemove:(id)sender
{}

- (IBAction)pressedAddGroup:(id)sender
{}

- (IBAction)selectedAddLanguage:(id)sender
{
    NSLog(@"selected: %@", popLanguageAdd.selectedItem);
}

@end
