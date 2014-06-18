//
//  LocalizationTranslateWindow.h
//  SpriteBuilder
//
//  Created by Benjamin Koatz on 6/4/14.
//
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@class LocalizationEditorLanguage;
@class LocalizationEditorWindow;

@interface LocalizationTranslateWindow : NSWindowController <NSTableViewDataSource, NSTableViewDelegate, NSTextViewDelegate, NSSplitViewDelegate, SKProductsRequestDelegate, SKPaymentTransactionObserver>
{
    NSEvent * (^monitorHandler)(NSEvent *);
    IBOutlet NSButton *_buy;
    NSEvent* eventMon;
    IBOutlet NSTableView* _languageTable;
    IBOutlet NSTextField* _numWords;
    IBOutlet NSTextField* _numWordsText;
    IBOutlet NSTextField* _cost;
    IBOutlet NSTextField* _costText;
    IBOutlet NSPopUpButton* _popTranslateFrom;
    IBOutlet NSButton* _translateFromInfo;
    NSTextView *_translateFromInfoV;
    NSPopover *_translatePopOver;
    IBOutlet NSTextField* _noActiveLangsError;
    IBOutlet NSButton* _ignoreText;
    IBOutlet NSButton* _checkAll;
    IBOutlet NSButton* _cancel;
    IBOutlet NSProgressIndicator* _languagesDownloading;
    IBOutlet NSTextField* _languagesDownloadingText;
    IBOutlet NSProgressIndicator* _costDownloading;
    IBOutlet NSTextField* _costDownloadingText;
    NSViewController *_translateInfoVC;
    NSMutableArray* _phrasesToTranslate;
    NSMutableArray* _activeLanguages;
    NSMutableDictionary* _languages;
    NSInteger _tierForTranslations;
    NSArray *_products;
    NSString* _guid;
    NSMutableDictionary* _receipts;
    NSInteger _numTransToDownload;
    NSTimer* _timerTransDownload;
    IBOutlet NSTextField* _translationsDownloadText;
    IBOutlet NSProgressIndicator* _translationsProgressBar;
    LocalizationEditorLanguage* _currLang;
}
- (IBAction)buy:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)toggleIgnore:(id)sender;
- (IBAction)selectedTranslateFromMenu:(id)sender;
- (IBAction)toggleCheckAll:(id)sender;
- (IBAction)showInfo:(id)sender;
- (void)reloadLanguageMenu;
- (void)reloadCost;
@property (strong) IBOutlet NSButton *buy;
@end