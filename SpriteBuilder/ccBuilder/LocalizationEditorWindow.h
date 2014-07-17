//
//  LocalizationEditorWindow.h
//  SpriteBuilder
//
//  Created by Viktor on 8/6/13.
//
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@class LocalizationTranslateWindow;
@class LocalizationCancelTranslationsWindow;
@interface LocalizationEditorWindow : NSWindowController <NSTableViewDataSource, NSTableViewDelegate, NSTextViewDelegate, NSSplitViewDelegate>
{
    IBOutlet NSTableView* tableTranslations;
    IBOutlet NSTableView* tableLanguages;
    IBOutlet NSPopUpButton* popLanguageAdd;
    IBOutlet NSButton* _addTranslation;
    IBOutlet NSPopUpButton* popCurrentLanguage;
    IBOutlet NSTextView* textInspectorKey;
    IBOutlet NSTextField* _translationProgressText;
    IBOutlet NSProgressIndicator* _translationProgress;
    IBOutlet NSButton* _translationsButton;
    LocalizationTranslateWindow* _ltw;
    LocalizationCancelTranslationsWindow* _lctw;
}

@property (nonatomic,assign) BOOL inspectorEnabled;
@property (nonatomic,strong) LocalizationTranslateWindow* ltw;
@property (nonatomic,copy) NSAttributedString* inspectorTextKey;
@property (nonatomic,copy) NSAttributedString* inspectorTextComment;
@property (nonatomic,copy) NSAttributedString* inspectorTextTranslation;
@property (nonatomic,copy) NSString* startTextValue;
@property (nonatomic,assign) BOOL hasOpenFile;

- (IBAction)pressedAdd:(id)sender;
- (IBAction)pressedAddGroup:(id)sender;
- (IBAction)pressedTranslate:(id)sender;

- (IBAction)selectedAddLanguage:(id)sender;
- (void)removeLanguagesAtIndexes:(NSIndexSet*)idxs;
- (IBAction)selectedCurrentLanguage:(id)sender;
- (void)addLanguages:(NSArray*)langs;
- (void)setDownloadingTranslations;
- (void)incrementTransByOne;
- (double)translationProgress;
- (void)finishDownloadingTranslations;

- (void)removeTranslationsAtIndexes:(NSIndexSet*)idxs;

- (void) reload;
- (void) selectRow:(int)row;

@end
