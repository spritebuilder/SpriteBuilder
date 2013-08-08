//
//  LocalizationEditorWindow.h
//  SpriteBuilder
//
//  Created by Viktor on 8/6/13.
//
//

#import <Foundation/Foundation.h>

@interface LocalizationEditorWindow : NSWindowController <NSTableViewDataSource, NSTableViewDelegate>
{
    IBOutlet NSTableView* tableTranslations;
    IBOutlet NSTableView* tableLanguages;
    IBOutlet NSPopUpButton* popLanguageAdd;
    IBOutlet NSPopUpButton* popCurrentLanguage;
}

@property (nonatomic,assign) BOOL inspectorEnabled;

@property (nonatomic,copy) NSAttributedString* inspectorTextKey;
@property (nonatomic,copy) NSAttributedString* inspectorTextComment;
@property (nonatomic,copy) NSAttributedString* inspectorTextTranslation;

- (IBAction)pressedAdd:(id)sender;
- (IBAction)pressedAddGroup:(id)sender;

- (IBAction)selectedAddLanguage:(id)sender;
- (void)removeLanguagesAtIndexes:(NSIndexSet*)idxs;
- (IBAction)selectedCurrentLanguage:(id)sender;

@end
