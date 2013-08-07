//
//  LocalizationEditorWindow.h
//  SpriteBuilder
//
//  Created by Viktor on 8/6/13.
//
//

#import <Foundation/Foundation.h>

@interface LocalizationEditorWindow : NSWindowController <NSTableViewDataSource>
{
    IBOutlet NSTableView* tableTranslations;
    IBOutlet NSTableView* tableLanguages;
    IBOutlet NSPopUpButton* popLanguageAdd;
    IBOutlet NSPopUpButton* popCurrentLanguage;
}

- (IBAction)pressedAdd:(id)sender;
- (IBAction)pressedAddGroup:(id)sender;

- (IBAction)selectedAddLanguage:(id)sender;

@end
