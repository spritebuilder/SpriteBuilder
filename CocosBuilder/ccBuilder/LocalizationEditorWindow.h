//
//  LocalizationEditorWindow.h
//  SpriteBuilder
//
//  Created by Viktor on 8/6/13.
//
//

#import <Foundation/Foundation.h>

@interface LocalizationEditorWindow : NSWindowController
{
    IBOutlet NSTableView* tableView;
    IBOutlet NSPopUpButton* popLanguageAdd;
}

- (IBAction)pressedAdd:(id)sender;
- (IBAction)pressedAddGroup:(id)sender;

- (IBAction)selectedAddLanguage:(id)sender;

@end
