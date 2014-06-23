//
//  LocalizationTranslateWindow.m
//  SpriteBuilder
//
//  Created by Benjamin Koatz on 6/4/14.
//
//

#import "LocalizationTranslateWindow.h"
#import "LocalizationEditorHandler.h"
#import "AppDelegate.h"
#import "LocalizationEditorLanguage.h"
#import "LocalizationEditorTranslation.h"
#import "LocalizationEditorWindow.h"
#import "LocalizationTranslateWindowHandler.h"

@implementation LocalizationTranslateWindow

static int downloadLangsIndex = 0;
static int noActiveLangsIndex = 1;
static int standardLangsIndex = 2;
/*
 * Set up the guid, the languages global dictionary and get the dictionary's contents from the server
 */
-(void) awakeFromNib
{
    //_guid = [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] objectForKey:@"sbUserID"];
    _guid = [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] objectForKey:@"PayloadUUID"];
    _languages = [[NSMutableDictionary alloc] init];
    [[_translateFromTabView tabViewItemAtIndex:downloadLangsIndex] setView:_downloadingLangsView];
    [[_translateFromTabView tabViewItemAtIndex:noActiveLangsIndex] setView:_noActiveLangsView];
    [[_translateFromTabView tabViewItemAtIndex:standardLangsIndex] setView:_standardLangsView];
    [self getLanguagesFromServer];
    [_w setPopOver:_translatePopOver button:_translateFromInfo];
}

/*
 * Once the languages are retrieved, this is called. The spinning wheel and 
 * message indicating downloading languages are hidden. All languages' quickEdit
 * settings are checked off, and if there are active languages, the pop-up
 * 'translate from' menu is set up and, in that function, the language table's
 * data is reload. If there are no active languages that we can translate from
 * then a the pop-up menu is disabled, an error message with instructions is shown.
 */
-(void)finishSetUp{
    
    [_languagesDownloading stopAnimation:self];
    [self uncheckLanguageDict];
    if(_activeLanguages.count)
    {
        [_translateFromTabView selectTabViewItemAtIndex:standardLangsIndex];
        [_popTranslateFrom setEnabled:1];
        LocalizationEditorLanguage* l = [_activeLanguages objectAtIndex:0];
        _popTranslateFrom.title = l.name;
        _currLang = l;
        [self updateLanguageSelectionMenu:1];
    }
    else
    {
        _currLang = NULL;
        _popTranslateFrom.title = @"No Active Languages!";
        [self updateNoActiveLangsError];
        [_translateFromTabView selectTabViewItemAtIndex:noActiveLangsIndex];
    }
}

/*
 * Turns off the 'quick edit' option in the languages global dictionary
 */
-(void)uncheckLanguageDict{
    for(LocalizationEditorLanguage* l in [_languages allKeys])
    {
        l.quickEdit = 0;
        for(LocalizationEditorLanguage* l2 in [_languages objectForKey:l])
            l2.quickEdit = 0;
    }
}

/*
 * If this is coming out of a reload of the menu (the initial post-download call or reload 
 * after a language is added on the Language Translation window) everything is normal. But
 * if this is just a normal user selection, and the user reselected the current language, 
 * ignore this and return.
 *
 * Otherwise, remove all items from the menu, then put all the active langauges back into it.
 * Set the global currLang to the newly selected language and if this isn't the initial
 * update (e.g. if the window is already loaded and someone is selecting a new language
 * to translate from) then update the main language table and the check all box accordingly.
 * If there are still languages that can be activated, update and show the missing active 
 * languages message.
 */
- (void) updateLanguageSelectionMenu:(NSInteger)isReload
{
    NSString* newLangSelection = _popTranslateFrom.selectedItem.title;
    if(self.isWindowLoaded && _currLang && !isReload && [newLangSelection isEqualToString:_currLang.name])
    {
        return;
    }
    if(!_currLang)
    {
        newLangSelection = ((LocalizationEditorLanguage*)[_activeLanguages objectAtIndex:0]).name;
    }
    
    [_popTranslateFrom removeAllItems];
    NSMutableArray* langTitles = [NSMutableArray array];
    for (LocalizationEditorLanguage* lang in _activeLanguages)
    {
        if([lang.name isEqualToString:newLangSelection])
        {
            _currLang = lang;
        }
        [langTitles addObject:lang.name];
    }
    [_popTranslateFrom addItemsWithTitles:langTitles];
    
    if (newLangSelection)
    {
        [_popTranslateFrom selectItemWithTitle:newLangSelection];
    }
    if([self isWindowLoaded])
    {
        [_languageTable reloadData];
        [self updateCheckAll];
    }
    if(_activeLanguages.count == [_languages allKeys].count)
    {
        if(_translatePopOver.isShown)
        {
            [_translatePopOver close];
        }
        [_translateFromInfo setHidden:1];
    }
    else{
        [_translateFromInfo setHidden:0];
    }
}


/*
 * Counts the number of words in a string, counting words
 * as space-separated sets of letters, including - and '.
 * TODO line this up with unbabel's way of delimiting
 * what's a word and what's not
 */
-(NSInteger) numWordsInPhrase:(NSString*) phrase{
    NSInteger l = phrase.length;
    NSInteger words = 0;
    NSInteger lastWasLetter = 0;
    NSInteger firstLetterReached = 0;
    NSMutableCharacterSet* letters = [NSMutableCharacterSet letterCharacterSet];
    [letters addCharactersInString:@"-'"];
    for(NSInteger i=0; i<l; i++)
    {
        if([letters characterIsMember:[phrase characterAtIndex:i]] &&
           !firstLetterReached)
        {
            firstLetterReached = 1;
            words++;
        }
        else if(![letters characterIsMember:[phrase characterAtIndex:i]] && lastWasLetter)
        {
            words++;
            lastWasLetter = 0;
            continue;
        }
        lastWasLetter = 1;
    }
    return words;
}

/*
 * Goes through every LocalizationEditorTranslation, first seeing if there is a
 * version of the phrase in the 'translate from' language. Then populating an array
 * of the isoCodes for every translation which doesn't exist for the selected 'translate
 * to' languages (or filling the array with every 'translate to' language if the user
 * has selected not to ignore translation they have already input). If the array remains
 * unpopulated, then we ignore this translation. We then count the number of words in the
 * 'translate from' string and multiply that by the number of languages to translate to
 * to find how many words need to be translated. Then we create a dictionary of the
 * 'translate from' text, the context (if it exists), the source language, the languages
 * to translate to and add that dictionary to an array of phrases.
 * Return the number of words in the phrasesToTranlsate array.
 */
-(NSInteger)updatePhrasesToTranslate{
    LocalizationEditorHandler* handler = [AppDelegate appDelegate].localizationEditorHandler;
    NSMutableArray* trans = handler.translations;
    [_phrasesToTranslate removeAllObjects];
    NSInteger words = 0;
    for(LocalizationEditorTranslation* t in trans)
    {
        NSString* toTranslate = [t.translations objectForKey:_currLang.isoLangCode];
        if(!toTranslate || [toTranslate isEqualToString:@""])
        {
            continue;
        }
        NSMutableArray* langsToTranslate = [[NSMutableArray alloc] init];
        for(LocalizationEditorLanguage* l in [_languages objectForKey:_currLang])
        {
            NSString* tempTrans = [t.translations objectForKey:l.isoLangCode];
            if((!tempTrans  || [tempTrans isEqualToString:@""]) || !_ignoreText.state)
            {
                if(l.quickEdit)
                {
                    [langsToTranslate addObject:l.isoLangCode];
                }
            }
        }
        if(!langsToTranslate.count)
        {
            continue;
        }
        _numTransToDownload += langsToTranslate.count;
        words += langsToTranslate.count*[self numWordsInPhrase:toTranslate];
        NSDictionary *phrase;
        if(t.comment && ![t.comment isEqualToString:@""])
        {
            phrase = [[NSDictionary alloc] initWithObjectsAndKeys:
                      t.key, @"key",
                   [t.translations objectForKey:_currLang.isoLangCode], @"text",
                   t.comment, @"context",
                   _currLang.isoLangCode,@"source_language",
                   langsToTranslate,@"target_languages",
                   nil];
        }
        else
        {
            phrase = [[NSDictionary alloc] initWithObjectsAndKeys:
                      t.key, @"key",
                   [t.translations objectForKey:_currLang.isoLangCode], @"text",
                   _currLang.isoLangCode,@"source_language",
                   langsToTranslate,@"target_languages",
                   nil];
        }
        [_phrasesToTranslate addObject:phrase];
    }
    return words;
}

/*
 * Gets the estimated cost of a translation request using the currrent user-set parameters.
 * Updates phrases to translate, returning the number of words the user is asking to 
 * translate. Updates the numWords field in the window (if there are 0 words to translate,
 * cost is 0 and we finish). 
 *
 * We then start the spinning download image and a download message, and send the array of 
 * phrases as a post request to the the 'estimate' spritebuilder URL, and receive the number 
 * of the appropriate Apple Price Tier. We then send that price tier to Apple to come up with 
 * the appropriate, localized price.
 * TODO uncomment HTTP request.
 */
-(void) getCost{
    
    NSInteger words = [self updatePhrasesToTranslate];
    _numWords.stringValue = [NSString stringWithFormat:@"%ld", words];
    if(_numWords.stringValue.intValue == 0)
    {
        _cost.stringValue = [NSString stringWithFormat:@"%ld", words];
        return;
    }
    [_costDownloading setHidden:0];
    [_costDownloadingText setHidden:0];
    [_costDownloading startAnimation:self];
     NSDictionary *JSONObject = [[NSDictionary alloc] initWithObjectsAndKeys:
                                 _guid,@"key",
                                 _phrasesToTranslate,@"phrases",
                                 nil];
     NSError *error;
     NSData *postdata2 = [NSJSONSerialization dataWithJSONObject:JSONObject options:0 error:&error];
     NSURL *url = [NSURL URLWithString:@"http://spritebuilder-rails.herokuapp.com/translations/estimate"];
     NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
     request.HTTPMethod = @"POST";
     request.HTTPBody = postdata2;
     /*NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest: request
                                                                  completionHandler:^(NSData *data,
                                                                                      NSURLResponse *response,
                                                                                      NSError *error)
    {
                    if (!error)
                    {
                        NSDictionary* dataDict = (NSDictionary *)data;
                        tierForTranslations  = [[dataDict objectForKey:@"tier"] intValue];
                        NSLog(@"Status code: %li", ((NSHTTPURLResponse *)response).statusCode);
                    }
                    else
                    {
                        NSLog(@"Error: %@", error.localizedDescription);
                    }
     }];
     [task resume];*/
    _tierForTranslations = 1;
    [self requestIAPProducts];
}

/*
 * Get the IAP PIDs from the correct plist, put those into a Products Request and start that request.
 */
-(void)requestIAPProducts{
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"LocalizationInAppPurchasesPIDs" withExtension:@".plist"];
    NSArray *productIdentifiers = [NSArray arrayWithContentsOfURL:url];
    NSSet* identifierSet = [NSSet setWithArray:productIdentifiers];
    SKProductsRequest* request = [[SKProductsRequest alloc] initWithProductIdentifiers:identifierSet];
    request.delegate = self;
    [request start];
}


/*
 * Start the spinning download icon, disable and put a message in the menu and show the downloading text.
 * Get languages from server and update active langauges. Once the session is done the JSON data will be
 * parsed if there wasn't an error.
 */
-(void)getLanguagesFromServer{
    _popTranslateFrom.title = @"Downloading...";
    [_popTranslateFrom setEnabled:0];
    [_translateFromTabView selectTabViewItemAtIndex:downloadLangsIndex];
    [_languagesDownloading startAnimation:self];
    NSString* URLstring =
        [NSString stringWithFormat:@"http://spritebuilder-rails.herokuapp.com/translations/languages?key=%@", _guid];
    NSURL* url = [NSURL URLWithString:URLstring];
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL: url
                                                                 completionHandler:^(NSData *data,
                                                                                     NSURLResponse *response,
                                                                                     NSError *error)
                                  {
                                      if (!error)
                                      {
                                          [self parseJSONLanguages:data];
                                          NSLog(@"Status code: %li", ((NSHTTPURLResponse *)response).statusCode);
                                      }
                                      else
                                      {
                                          NSLog(@"Error: %@", error.localizedDescription);
                                      }
                                  }];
    [task resume];
}

/*
 * Turns the JSON response into a dictionary and fill the _languages global accordingly.
 * Then update the active languages array, the pop-up menu and the table. This is
 * only done once in the beginning of the SpriteBuilder session.
 */
-(void)parseJSONLanguages:(NSData *)data{
    NSError *JSONerror;
    NSMutableDictionary* availableLanguagesDict = [NSJSONSerialization JSONObjectWithData:data
                                                    options:NSJSONReadingMutableContainers error:&JSONerror];
    if(JSONerror)
    {
        NSLog(@"JSONError: %@", JSONerror.localizedDescription);
        return;
    }
    for(NSString* lIso in availableLanguagesDict.allKeys)
    {
        NSMutableArray* translateTo = [[NSMutableArray alloc] init];
        for(NSString* translateToIso in (NSArray *)[availableLanguagesDict objectForKey:lIso])
        {
            [translateTo addObject:[[LocalizationEditorLanguage alloc] initWithIsoLangCode:translateToIso]];
        }
        [_languages setObject:translateTo forKey:[[LocalizationEditorLanguage alloc] initWithIsoLangCode:lIso]];
    }
    [self updateActiveLanguages];
    [self finishSetUp];
}

/*
 * Remove active languages not in the keys of the global languages dictionary
 */
-(void)updateActiveLanguages{
    LocalizationEditorHandler* handler = [AppDelegate appDelegate].localizationEditorHandler;
    _activeLanguages = [[NSMutableArray alloc] initWithArray:handler.activeLanguages];
    NSMutableArray* activeLangsCopy = _activeLanguages.copy;
    for(LocalizationEditorLanguage* l in activeLangsCopy)
    {
        if(![[_languages allKeys] containsObject:l])
        {
            [_activeLanguages removeObject:l];
        }
    }
}

/*
 * Solicit a payment and set the cancel button to say 'Finish'.
 */
- (IBAction)buy:(id)sender {
    //[_buy setState:NSOnState];
    SKPayment* payment = [SKPayment paymentWithProduct:[_products objectAtIndex:(_tierForTranslations -1)]];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
    _cancel.title = @"Finish";
}

/*
 * Close the window.
 */
- (IBAction)cancel:(id)sender {
    [[sender window] close];
}

/*
 * If a user clicks or unclicks ignore then update the cost of the translations
 * they are seeking.
 */
- (IBAction)toggleIgnore:(id)sender {
    [self getCost];
}

/*
 * Update the langauge select menu if someone has selected the pop-up
 * 'translate from' menu. Send 0 because this is not a reload, it is a
 * user-click generated event.
 */
- (IBAction)selectedTranslateFromMenu:(id)sender {
    [self updateLanguageSelectionMenu:0];
}

/*
 * If the check all box has been clicked, turn off mixed state (so
 * people can only go from no check to check) and update the quickEdit
 * state of all languages in the array of 'translate to' langauges for 
 * the current language and reload the main language table.
 */
- (IBAction)toggleCheckAll:(id)sender {
    _checkAll.allowsMixedState = 0;
    for (LocalizationEditorLanguage* l in [_languages objectForKey:_currLang])
        l.quickEdit = _checkAll.state;
    [_languageTable reloadData];
}

- (IBAction)showInfo:(id)sender {
    [self updateMissingActiveLangs];
    if(_translateFromInfo.intValue == 1){
        [_translatePopOver showRelativeToRect:[_translateFromInfo bounds] ofView:_translateFromInfo preferredEdge:NSMaxYEdge];
    }else{
        [_translatePopOver close];
    }
}
/*
 * Once a new language is input to the Language Translate window's main
 * table, this is called to reload the cost in the translate window.
 */
- (void)reloadCost{
    [self getCost];
}

-(IBAction)unclick:(id)sender{
    [_translatePopOver close];
    [_translateFromInfo setIntValue:0];
}

/*
 * Update the active languages from the Language Translate window. If this
 * event is being percolated by a no active languages message, flash that 
 * message if the problem has not been fixed (e.g. they added a language 
 * that isn't in the keys of the language dictionary) or hide the message
 * and enable and update the menu. This situation is not considered a reload
 * for the purposes of updateLangaugesSelectionMenu. If this is being called because of a
 * missing languages message, hide that message if all possible active 
 * langauges are activated and then update the language menu. This situation
 * is considered a reload.
 */
- (void)reloadLanguageMenu{
    [self updateActiveLanguages];
    if([_translateFromTabView indexOfTabViewItem:[_translateFromTabView selectedTabViewItem]]
       == noActiveLangsIndex)
    {
        if(!_activeLanguages.count)
        {
            NSTimer* timer = [NSTimer scheduledTimerWithTimeInterval:0 target:self selector:@selector(toggleNoActiveLangsAlpha) userInfo:nil repeats:NO];
            timer = [NSTimer scheduledTimerWithTimeInterval:.1 target:self selector:@selector(toggleNoActiveLangsAlpha) userInfo:nil repeats:NO];
        }
        else
        {
            [_translateFromTabView selectTabViewItemAtIndex:standardLangsIndex];
            [_popTranslateFrom setEnabled:1];
            [self updateLanguageSelectionMenu: 0];
        }
    }else{
        if(!_activeLanguages.count)
        {
            [_translateFromTabView selectTabViewItemAtIndex:noActiveLangsIndex];
            [_translateFromInfo setHidden:1];
            [_popTranslateFrom setEnabled:0];
            _popTranslateFrom.title = @"No active languages!";
            _currLang = NULL;
            [_languageTable reloadData];
        }else{
            [self updateMissingActiveLangs];
            [self updateLanguageSelectionMenu: 1];
        }
    }
}

/*
 * Flashes the no active langauges error.
 */
- (void)toggleNoActiveLangsAlpha {
    [_noActiveLangsError setHidden:(!_noActiveLangsError.isHidden)];
}

/*
 * Put all the available but not inputted 'translate from' languages 
 * in the missing active langs message
 */
-(void)updateMissingActiveLangs{
    
    NSMutableString* s = [[NSMutableString alloc] initWithString:@""];
    for(LocalizationEditorLanguage* l in [_languages allKeys])
    {
        if(![_activeLanguages containsObject:l])
        {
            if(![s isEqualToString:@""])
            {
                [s appendString:@", "];
            }
            [s appendString:l.name];
        }
    }
    NSString* info = [NSString stringWithFormat: @"Additional translatable language(s): %@.\rTo activate, select \"Add Language\" in Language Translation window and add phrases you want to translate.", s];
    
    _translateFromInfoV.string = info;
}

/*
 * Put all the available 'translate from' languages in the no active languages error
 */
-(void)updateNoActiveLangsError{
    
    NSMutableString* s = [[NSMutableString alloc] initWithString:@""];
    for(LocalizationEditorLanguage* l in [_languages allKeys])
    {
        if(![s isEqualToString:@""])
        {
            [s appendString:@", "];
        }
        [s appendString:l.name];
    }
    _noActiveLangsError.stringValue = [NSString stringWithFormat:@"You haven't added any languages that we can translate! The languages you can translate from are: %@.\rAdd at least one of them in the Language Editor window and fill in the phrases you would like to translate.", s];
}
/*
 * Go through the dictionary of 'translate to' languages for the current language
 * and update the check all box accordingly
 */
-(void)updateCheckAll{
    BOOL checkAllFalse = 0;
    BOOL checkAllTrue = 1;
    for(LocalizationEditorLanguage* l in [_languages objectForKey:_currLang])
    {
        if(!l.quickEdit)
            checkAllTrue = 0;
        else
            checkAllFalse = 1;
    }
    if(checkAllFalse && !checkAllTrue)
    {
        _checkAll.allowsMixedState = 1;
        _checkAll.state = -1;
    }
    else if(!checkAllFalse)
    {
        _checkAll.allowsMixedState = 0;
        _checkAll.state = 0;
    }
    else
    {
        _checkAll.allowsMixedState = 0;
        _checkAll.state = 1;
    }
}

/*
 * Tableview delegate
 */

/*
 * If there's no current language then there's going to be nothing to
 * put in the tableView, so just return 0 for the size. Else, get the 
 * cost with the updated parameters and return the count of the array
 * of 'translate to' languages associate with the current language.
 */
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    
    if(!_currLang)
    {
        return 0;
    }
    [self getCost];
    NSInteger ret = ((NSArray*)[_languages objectForKey:_currLang]).count;
    return ret;
}

/*
 * If there's no current language then there's going to be nothing to put in the tableView, 
 * so just return 0. Else, just return the values for stuff from the 'translate from' array 
 * for the current language.
 */
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if(!_currLang){
     return 0;
    }
   if ([aTableColumn.identifier isEqualToString:@"enabled"])
    {
        LocalizationEditorLanguage* lang = [((NSArray*)[_languages objectForKey:_currLang]) objectAtIndex:rowIndex];
        return [NSNumber numberWithBool:lang.quickEdit];
    }
    else if ([aTableColumn.identifier isEqualToString:@"name"])
    {
        LocalizationEditorLanguage* lang = [((NSArray*)[_languages objectForKey:_currLang]) objectAtIndex:rowIndex];
        return lang.name;
    }
    return NULL;
}

/*
 * Update the check all box and get new cost when the user toggles one of the languages in the main language table.x
 */
- (void) tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if ([tableColumn.identifier isEqualToString:@"enabled"])
    {
        LocalizationEditorLanguage* lang = [((NSArray*)[_languages objectForKey:_currLang]) objectAtIndex:row];
        lang.quickEdit = [object boolValue];
        [self updateCheckAll];
        [self getCost];
    }
}

/*
 * Request Delegate
 */

/*
 * Takes in the products returned by apple, prints any invalid identifiers and displays
 * the price of those products.
 * TODO get rid of invalid product identifiers!
 */
-(void) productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response{
    _products = response.products;
    for(NSString *invalidIdentifier in response.invalidProductIdentifiers)
    {
        [_costDownloading setHidden:1];
        [_costDownloadingText setHidden:1];
        [_costDownloading stopAnimation:self];
        NSLog(@"Invalid Identifier: %@",invalidIdentifier);
        return;
    }
    [self displayPrice];
}

/*
 * Payments, prices and receipts
 */

/*
 * Locally format the price of the current translation estimate, display it,
 * and hide the cost downloading message and spinning icon.
 */
-(void)displayPrice{
    SKProduct* p = [_products objectAtIndex:(_tierForTranslations - 1)];
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [numberFormatter setLocale:p.priceLocale];
    NSString *formattedString = [numberFormatter stringFromNumber:p.price];
    _cost.stringValue = formattedString;
    [_costDownloading setHidden:1];
    [_costDownloadingText setHidden:1];
    [_costDownloading stopAnimation:self];
}

/*
 * Ask for a receipt for any updated paymnent transactions.
 */
-(void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions{
    NSURL* receiptURL;
    for (SKPaymentTransaction* transaction in transactions)
    {
        switch(transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased:
                receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
                NSData* receipt = [NSData dataWithContentsOfURL:receiptURL];
                [_receipts setObject:receipt forKey:transaction.transactionIdentifier];
                [self validateReceipt:receipt];
                break;
        }
    }
}

/*
 * Validates the receipt with our server.
 * TODO check for translations!
 */
-(void)validateReceipt:(NSData *)receipt{
    NSDictionary *JSONObject = [[NSDictionary alloc] initWithObjectsAndKeys:
                                _guid,@"key",
                                receipt,@"receipt",
                                _phrasesToTranslate,"@phrases",
                                nil];
    NSError *error;
    NSData *postdata2 = [NSJSONSerialization dataWithJSONObject:JSONObject options:0 error:&error];
    NSURL *url = [NSURL URLWithString:@"http://spritebuilder-rails.herokuapp.com/translations/receipt/"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    request.HTTPBody = postdata2;
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest: request
                                                             completionHandler:^(NSData *data,
                                                                                 NSURLResponse *response,
                                                                                 NSError *error)
                                  {
                                      if (!error)
                                      {
                                          [self showTranslationsDownloading];
                                          [self setLanguageWindowDownloading];
                                          [self parseJSONTranslations:data];
                                          _timerTransDownload = [NSTimer scheduledTimerWithTimeInterval:300 target:self selector:@selector(getTranslations) userInfo:nil repeats:YES];
                                          NSLog(@"Status code: %li", ((NSHTTPURLResponse *)response).statusCode);
                                      }
                                      else
                                      {
                                          NSLog(@"Error: %@", error.localizedDescription);
                                      }
                                  }];
    [task resume];
}

-(void)showTranslationsDownloading{
    [_translationsProgressBar startAnimation:self];
    [_translationsProgressBar setMaxValue:_numTransToDownload];
    [_translationsDownloadText setHidden:0];
    [_translationsProgressBar setHidden:0];
}

-(void)getTranslations{
    NSString* URLstring =
    [NSString stringWithFormat:@"http://spritebuilder-rails.herokuapp.com/translations?key=%@", _guid];
    NSURL* url = [NSURL URLWithString:URLstring];
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL: url
                                                             completionHandler:^(NSData *data,
                                                                                 NSURLResponse *response,
                                                                                 NSError *error)
                                  {
                                      if (!error)
                                      {
                                          
                                          [self parseJSONTranslations:data];
                                          NSLog(@"Status code: %li", ((NSHTTPURLResponse *)response).statusCode);
                                      }
                                      else
                                      {
                                          NSLog(@"Error: %@", error.localizedDescription);
                                      }
                                  }];
    [task resume];

}

-(void)setLanguageWindowDownloading{
    LocalizationEditorHandler* handler = [AppDelegate appDelegate].localizationEditorHandler;
    NSArray* translations = handler.translations;
    for(LocalizationEditorTranslation* t in translations){
        for(NSDictionary* d in _phrasesToTranslate){
            if([t.key isEqualToString:[d objectForKey:@"key"]]){
                t.languagesDownloading = [d objectForKey:@"target_languages"];
                break;
            }
        }
    }
}
/*
 * Turns the JSON response into a dictionary and fill the _languages global accordingly.
 * Then update the active languages array, the pop-up menu and the table. This is
 * only done once in the beginning of the SpriteBuilder session.
 */
-(void)parseJSONTranslations:(NSData *)data{
    NSError *JSONerror;
    NSDictionary* initialTransDict  = [NSJSONSerialization JSONObjectWithData:data
                                                                                  options:NSJSONReadingMutableContainers error:&JSONerror];
    if(JSONerror)
    {
        NSLog(@"JSONError: %@", JSONerror.localizedDescription);
        return;
    }
    LocalizationEditorHandler* handler = [AppDelegate appDelegate].localizationEditorHandler;
    NSArray* handlerTranslations = handler.translations;
    NSArray* initialTrans = [initialTransDict objectForKey:@"phrases"];
    for(NSDictionary* transForKeys in initialTrans)
    {
        NSString* keyToTranslate = [transForKeys.allKeys objectAtIndex:0];
        NSDictionary* transDict = [transForKeys objectForKey:keyToTranslate];
        for(NSString* lang in transDict.allKeys){
            NSString* translation = [transDict objectForKey:lang];
            for(LocalizationEditorTranslation* t in handlerTranslations)
            {
                if([t.key isEqualToString:keyToTranslate] && [t.languagesDownloading containsObject:lang]){
                    [t.translations setObject:translation forKey:lang];
                    [t.languagesDownloading removeObject:lang];
                    [_translationsProgressBar incrementBy:1];
                }
            }
        }
    }
    if(_translationsProgressBar.doubleValue == _numTransToDownload){
        [_timerTransDownload invalidate];
        [_translationsDownloadText setHidden:1];
        [_translationsProgressBar setHidden:1];
    }
    [_languageTable reloadData];
}


@end
