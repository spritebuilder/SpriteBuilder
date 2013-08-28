//
//  LocalizationEditorWindow.h
//  SpriteBuilder
//
//  Created by Viktor on 8/6/13.
//
//

#import <Foundation/Foundation.h>

@interface LocalizationEditorWindow : NSWindowController <NSTableViewDataSource, NSTableViewDelegate, NSTextViewDelegate, NSSplitViewDelegate>
{
    IBOutlet NSTableView* tableTranslations;
    IBOutlet NSTableView* tableLanguages;
    IBOutlet NSPopUpButton* popLanguageAdd;
    IBOutlet NSPopUpButton* popCurrentLanguage;
    IBOutlet NSTextView* textInspectorKey;
}

@property (nonatomic,assign) BOOL inspectorEnabled;

@property (nonatomic,copy) NSAttributedString* inspectorTextKey;
@property (nonatomic,copy) NSAttributedString* inspectorTextComment;
@property (nonatomic,copy) NSAttributedString* inspectorTextTranslation;
@property (nonatomic,copy) NSString* startTextValue;
@property (nonatomic,assign) BOOL hasOpenFile;

- (IBAction)pressedAdd:(id)sender;
- (IBAction)pressedAddGroup:(id)sender;

- (IBAction)selectedAddLanguage:(id)sender;
- (void)removeLanguagesAtIndexes:(NSIndexSet*)idxs;
- (IBAction)selectedCurrentLanguage:(id)sender;

- (void)removeTranslationsAtIndexes:(NSIndexSet*)idxs;

- (void) reload;
- (void) selectRow:(int)row;

@end
