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
    //tab views
    IBOutlet NSView* _noActiveLangsView;
    IBOutlet NSView* _standardLangsView;
    IBOutlet NSView* _downloadingLangsView;
    IBOutlet NSView* _downloadingLangsErrorView;
    IBOutlet NSView* _downloadingCostsErrorView;
    IBOutlet NSView* _paymentErrorView;
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
    NSString* _latestRequestID;
    LocalizationEditorWindow* _parentWindow;
    
}

- (id)initWithDownload:(NSString*)requestID parentWindow:(LocalizationEditorWindow*)pw numToDownload:(double)numTrans;
- (IBAction)buy:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)toggleIgnore:(id)sender;
- (IBAction)selectedTranslateFromMenu:(id)sender;
- (IBAction)toggleCheckAll:(id)sender;
- (IBAction)retryLanguages:(id)sender;
- (IBAction)retryCost:(id)sender;
- (void)cancelDownloadWithError:(NSError*)error;
- (void)pauseDownload;
- (void)restartDownload;
@property (nonatomic,strong) LocalizationEditorWindow* parentWindow;
@property (nonatomic,strong) NSString* guid;
@property (nonatomic,strong) NSMutableDictionary* languages;
@end