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
@class LocalizationTranslateWindowHandler;

@interface LocalizationTranslateWindow : NSWindowController <NSTableViewDataSource, NSTableViewDelegate, NSTextViewDelegate, NSSplitViewDelegate, SKProductsRequestDelegate, SKPaymentTransactionObserver, NSWindowDelegate>
{
    //info button
    NSPopover *_translatePopOver;
    NSTextView *_translateFromInfoV;
    NSViewController *_translateInfoVC;
    IBOutlet NSButton* _translateFromInfo;
    
    //Window Handler (To deal with mouse events)
    IBOutlet LocalizationTranslateWindowHandler* _handler;
    
    //tab views
    IBOutlet NSView* _noActiveLangsView;
    IBOutlet NSView* _standardLangsView;
    IBOutlet NSView* _downloadingLangsView;
    IBOutlet NSView* _downloadingLangsErrorView;
    IBOutlet NSView* _downloadingCostsErrorView;
    IBOutlet NSTabView* _translateFromTabView;
    
    //fields inside tab views
    IBOutlet NSTextField* _numWords;
    IBOutlet NSTextField* _cost;
    IBOutlet NSTextField* _noActiveLangsError;
    IBOutlet NSProgressIndicator* _languagesDownloading;
    IBOutlet NSProgressIndicator* _costDownloading;
    IBOutlet NSTextField* _costDownloadingText;
    IBOutlet NSButton* _ignoreText;
    
    //Language menus
    IBOutlet NSPopUpButton* _popTranslateFrom;
    IBOutlet NSTableView* _languageTable;
    IBOutlet NSButton* _checkAll;
    
    //Buttons
    IBOutlet NSButton* _cancel;
    IBOutlet NSButton *_buy;
    
    //Translations downloading stuff
    IBOutlet NSTextField* _translationsDownloadText;
    IBOutlet NSProgressIndicator* _translationsProgressBar;
    NSInteger _numTransToDownload;
    NSTimer* _timerTransDownload;
    
    //Global variables
    LocalizationEditorLanguage* _currLang;
    NSMutableDictionary* _languages;
    NSMutableArray* _activeLanguages;
    NSMutableArray* _phrasesToTranslate;
    NSInteger _tierForTranslations;
    NSArray* _products;
    NSString* _guid;
    NSMutableDictionary* _receipts;
    
    LocalizationEditorWindow* _parentWindow;
    
}

- (IBAction)buy:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)toggleIgnore:(id)sender;
- (IBAction)selectedTranslateFromMenu:(id)sender;
- (IBAction)toggleCheckAll:(id)sender;
- (IBAction)showInfo:(id)sender;
- (IBAction)retryLanguages:(id)sender;
- (IBAction)retryCost:(id)sender;
- (void)reloadLanguageMenu;
- (void)reloadCost;

@property (nonatomic,strong) LocalizationEditorWindow* parentWindow;

@end