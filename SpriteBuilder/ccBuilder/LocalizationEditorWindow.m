//
//  LocalizationEditorWindow.m
//  SpriteBuilder
//
//  Created by Viktor on 8/6/13.
//
//

#import "LocalizationTranslateWindow.h"
#import "LocalizationEditorWindow.h"
#import "LocalizationEditorLanguage.h"
#import "LocalizationEditorHandler.h"
#import "LocalizationEditorTranslation.h"
#import "LocalizationEditorLanguageTableView.h"
#import "LocalizationTranslateWindowHandler.h"
#import "AppDelegate.h"
#import "CCBTextFieldCell.h"
#import "NSPasteboard+CCB.h"
#import "ProjectSettings.h"
@implementation LocalizationEditorWindow
@synthesize ltw =  _ltw;

- (void) awakeFromNib
{
    [tableTranslations registerForDraggedTypes:[NSArray arrayWithObject:@"com.cocosbuilder.LocalizationEditorTranslation"]];
    [self populateLanguageAddMenu];
    [tableLanguages reloadData];
    [self updateLanguageSelectionMenu];
    [self addLanguageColumns];
    [self updateQuickEditLangs];
    [self addObserver:self forKeyPath:@"hasOpenFile" options:0 context:nil];
}

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

- (void) updateLanguageSelectionMenu
{
    NSArray* langs = [AppDelegate appDelegate].localizationEditorHandler.activeLanguages;
    
    NSString* currentName = popCurrentLanguage.selectedItem.title;
    
    [popCurrentLanguage removeAllItems];
    
    NSMutableArray* langTitles = [NSMutableArray array];
    for (LocalizationEditorLanguage* lang in langs)
    {
        [langTitles addObject:lang.name];
    }
    
    [popCurrentLanguage addItemsWithTitles:langTitles];
    
    if (currentName)
    {
        [popCurrentLanguage selectItemWithTitle:currentName];
    }
}

- (void) addLanguageColumns
{
    NSArray* langs = [AppDelegate appDelegate].localizationEditorHandler.languages;
    
    for (LocalizationEditorLanguage* lang in langs)
    {
        NSTableColumn* column = [[NSTableColumn alloc] initWithIdentifier:lang.isoLangCode];
        column.width = 200;
        column.maxWidth = 1000;
        column.minWidth = 100;
        [[column headerCell] setStringValue:lang.name];
        
        CCBTextFieldCell* cell = [[CCBTextFieldCell alloc] init];
        [cell setEditable:YES];
        [cell setFont:[NSFont systemFontOfSize:11]];
        [column setDataCell:cell];
        
        [tableTranslations addTableColumn:column];
    }
}

- (void) updateQuickEditLangs
{
    NSArray* activeLangs = [AppDelegate appDelegate].localizationEditorHandler.activeLanguages;
    NSArray* allLangs = [AppDelegate appDelegate].localizationEditorHandler.languages;
    
    for (LocalizationEditorLanguage* lang in allLangs)
    {
        // Find column for language
        NSTableColumn* col = [tableTranslations tableColumnWithIdentifier:lang.isoLangCode];
        
        if ([activeLangs containsObject:lang] && lang.quickEdit)
        {
            [col setHidden:NO];
        }
        else
        {
            [col setHidden:YES];
        }
    }
}

- (LocalizationEditorLanguage*) selectedLanguage
{
    LocalizationEditorHandler* handler = [AppDelegate appDelegate].localizationEditorHandler;
    
    NSString* name = [popCurrentLanguage selectedItem].title;
    return [handler getLanguageByName:name];
}

- (void) updateInspector
{
    LocalizationEditorHandler* handler = [AppDelegate appDelegate].localizationEditorHandler;
    NSInteger row = [tableTranslations selectedRow];
    
    if (row == -1)
    {
        // Disable things
        self.inspectorTextKey = NULL;
        self.inspectorTextComment = NULL;
        self.inspectorTextTranslation = NULL;
    }
    else
    {
        self.inspectorEnabled = YES;
        
        LocalizationEditorTranslation* translation = [handler.translations objectAtIndex:row];
        
        if (translation.key)
        {
            self.inspectorTextKey = [[NSAttributedString alloc] initWithString:translation.key];
        }
        else
        {
            self.inspectorTextKey = NULL;
        }
        
        if (translation.comment)
        {
            self.inspectorTextComment = [[NSAttributedString alloc] initWithString:translation.comment];
        }
        else
        {
            self.inspectorTextComment = NULL;
        }
        
        LocalizationEditorLanguage* lang = [self selectedLanguage];
        NSString* currentTranslation = [translation.translations objectForKey:lang.isoLangCode];
        if (currentTranslation)
        {
            self.inspectorTextTranslation = [[NSAttributedString alloc] initWithString:currentTranslation];
        }
        else
        {
            self.inspectorTextTranslation = NULL;
        }
        if (!lang)
        {
            self.inspectorEnabled = NO;
        }
    }
}

- (void) reload
{
    [tableLanguages deselectAll:NULL];
    [tableLanguages reloadData];
    [tableTranslations deselectAll:NULL];
    [tableTranslations reloadData];
    
    [self updateLanguageSelectionMenu];
    [self updateQuickEditLangs];
    [self updateInspector];
}

#pragma mark Actions

- (IBAction)pressedAdd:(id)sender
{
    LocalizationEditorHandler* handler = [AppDelegate appDelegate].localizationEditorHandler;
    
    LocalizationEditorTranslation* translation = [[LocalizationEditorTranslation alloc] init];
    
    [handler.translations addObject:translation];
    [tableTranslations reloadData];
    
    NSInteger newRow = handler.translations.count -1;
    
    [tableTranslations selectRowIndexes:[NSIndexSet indexSetWithIndex:newRow] byExtendingSelection:NO];
    [tableTranslations editColumn:1 row:newRow withEvent:NULL select:YES];
}

- (IBAction)pressedAddGroup:(id)sender
{}

- (IBAction)selectedAddLanguage:(id)sender
{
    NSString* name = popLanguageAdd.selectedItem.title;
    
    LocalizationEditorHandler* handler = [AppDelegate appDelegate].localizationEditorHandler;
    [handler addActiveLanguage:[handler getLanguageByName:name]];
    
    [tableLanguages reloadData];
    [self updateLanguageSelectionMenu];
    [self updateQuickEditLangs];
    [self updateInspector];
    
    [handler setEdited];
}

/*
 * If you are opening a new window and one doesn't exist, open it and make it modal.
 * If you are cancelling a download, show a cancel alert, and if the user 'okays' the cancel,
 * stop the download.
 */
- (IBAction)pressedTranslate:(id)sender {
    
    if([_translationsButton.title isEqualToString:@"Buy Translations..."])
    {
        if(!_ltw)
        {
            _ltw = [[LocalizationTranslateWindow alloc] initWithWindowNibName:@"LocalizationTranslateWindow"];
        }
        [_ltw setParentWindow:self];
        [_ltw.window makeKeyAndOrderFront:sender];
        [NSApp runModalForWindow:_ltw.window];
    }
    else
    {
        NSAlert* alert = [NSAlert alertWithMessageText:@"Stop Download" defaultButton:@"Cancel" alternateButton:@"OK" otherButton:NULL informativeTextWithFormat:@"If you stop your translations download, you will not get a refund."];
        NSInteger result = [alert runModal];
        if(result == NSAlertAlternateReturn)
        {
            [self finishDownloadingTranslations];
            [_ltw cancelDownloadWithError:nil];
            [tableLanguages reloadData];
        }
    }
}

/*
 * Add languages to the language table (called when a translation request includes 'translate to' languages
 * that aren't already in the table.
 */
- (void)addLanguages:(NSArray*)langs
{
    LocalizationEditorHandler* handler = [AppDelegate appDelegate].localizationEditorHandler;
    for(NSString* iso in langs)
    {
        if([iso isEqualToString:@"zh"])
        {
            [handler addActiveLanguage:[handler getLanguageByIsoLangCode:@"zh-Hans"]];
        }
        else
        {
            [handler addActiveLanguage:[handler getLanguageByIsoLangCode:iso]];
        }
    }
    [tableLanguages reloadData];
    [self updateLanguageSelectionMenu];
    [self updateQuickEditLangs];
    [self updateInspector];
}

/*
 * Turn the window into a 'dowloading' one by setting the 'isDownloading' variable in the 
 * project settings and disabling everything except translation progress and the cancel button.
 */

-(void)setDownloadingTranslations{
    ProjectSettings* ps = [AppDelegate appDelegate].projectSettings;
    ps.isDownloadingTranslations = 1;
    [_translationProgress setMaxValue:ps.numToDownload];
    [_translationProgress setDoubleValue:ps.numDownloaded];
    [_translationProgress setHidden:0];
    [_translationProgressText setHidden:0];
    [tableTranslations setEnabled:0];
    [tableLanguages setEnabled:0];
    [popLanguageAdd setEnabled:0];
    [_addTranslation setEnabled:0];
    [popCurrentLanguage setEnabled:0];
    _translationsButton.title = @"Stop Download...";
}

/*
 * Make the translation progress bar increase by one
 */
-(void)incrementTransByOne{
    ProjectSettings* ps = [AppDelegate appDelegate].projectSettings;
    ps.numDownloaded++;
    [_translationProgress incrementBy:1.0];
}

/*
 * Retrieve translation progress information.
 */
- (double)translationProgress{
    return _translationProgress.doubleValue;
}

/*
 * Turn the window into a normal, non-dowloading one by setting the 'isDownloading'
 * in the project settings to 0 and enabling everything and hiding the translation
 * progress information.
 */
-(void)finishDownloadingTranslations{
    ProjectSettings* ps = [AppDelegate appDelegate].projectSettings;
    ps.isDownloadingTranslations = 0;
    ps.numDownloaded = 0;
    ps.numToDownload = 0;
    [_translationProgress setHidden:1];
    [_translationProgressText setHidden:1];
    [tableTranslations setEnabled:1];
    [tableLanguages setEnabled:1];
    [popLanguageAdd setEnabled:1];
    [popCurrentLanguage setEnabled:1];
    [_addTranslation setEnabled:1];
    _translationsButton.title = @"Buy Translations...";
}

- (void)removeLanguagesAtIndexes:(NSIndexSet*)idxs
{
    LocalizationEditorHandler* handler = [AppDelegate appDelegate].localizationEditorHandler;
    
    NSArray* langsToRemove = [handler.activeLanguages objectsAtIndexes:idxs];
    
    for (LocalizationEditorLanguage* lang in langsToRemove)
    {
        [handler removeActiveLangage:lang];
    }
    
    [tableLanguages reloadData];
    [self updateLanguageSelectionMenu];
    [self updateQuickEditLangs];
    [self updateInspector];
    [handler setEdited];
}

- (IBAction)selectedCurrentLanguage:(id)sender
{
    [self updateInspector];
}
- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    

}

- (void)removeTranslationsAtIndexes:(NSIndexSet*)idxs
{
    LocalizationEditorHandler* handler = [AppDelegate appDelegate].localizationEditorHandler;
    
    [handler.translations removeObjectsAtIndexes:idxs];
    
    [tableTranslations deselectAll:NULL];
    [tableTranslations reloadData];
    [self updateInspector];
    
    [handler setEdited];
}

- (void) selectRow:(int)row
{
    [tableTranslations selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
}

#pragma mark Properties for Inspector

- (void) setInspectorTextKey:(NSAttributedString *)inspectorTextKey
{
    LocalizationEditorHandler* handler = [AppDelegate appDelegate].localizationEditorHandler;
    NSInteger row = [tableTranslations selectedRow];
    
    if (row == -1) return;
    
    LocalizationEditorTranslation* translation = [handler.translations objectAtIndex:row];
    translation.key = [inspectorTextKey string];
    
    [tableTranslations reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row] columnIndexes:[NSIndexSet indexSetWithIndex:1]];
}

- (NSAttributedString*) inspectorTextKey
{
    LocalizationEditorHandler* handler = [AppDelegate appDelegate].localizationEditorHandler;
    NSInteger row = [tableTranslations selectedRow];
    
    if (row == -1) return NULL;
    
    LocalizationEditorTranslation* translation = [handler.translations objectAtIndex:row];
    
    if (!translation.key) return NULL;
    return [[NSAttributedString alloc] initWithString:translation.key];
}

- (void) setInspectorTextComment:(NSAttributedString *)inspectorTextComment
{
    LocalizationEditorHandler* handler = [AppDelegate appDelegate].localizationEditorHandler;
    NSInteger row = [tableTranslations selectedRow];
    
    if (row == -1) return;
    
    LocalizationEditorTranslation* translation = [handler.translations objectAtIndex:row];
    translation.comment = [inspectorTextComment string];
    
    [tableTranslations reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row] columnIndexes:[NSIndexSet indexSetWithIndex:2]];
}

- (NSAttributedString*) inspectorTextComment
{
    LocalizationEditorHandler* handler = [AppDelegate appDelegate].localizationEditorHandler;
    NSInteger row = [tableTranslations selectedRow];
    
    if (row == -1) return NULL;
    
    LocalizationEditorTranslation* translation = [handler.translations objectAtIndex:row];
    
    if (!translation.comment) return NULL;
    return [[NSAttributedString alloc] initWithString:translation.comment];
}

- (void) setInspectorTextTranslation:(NSAttributedString *)inspectorTextTranslation
{
    LocalizationEditorHandler* handler = [AppDelegate appDelegate].localizationEditorHandler;
    NSInteger row = [tableTranslations selectedRow];
    
    if (row == -1) return;
    
    LocalizationEditorTranslation* translation = [handler.translations objectAtIndex:row];
    LocalizationEditorLanguage* lang = [self selectedLanguage];
    
    if (!lang) return;
    
    if (inspectorTextTranslation)
    {
        [translation.translations setObject:[inspectorTextTranslation string] forKey:lang.isoLangCode];
    }
    else
    {
        [translation.translations removeObjectForKey:lang.isoLangCode];
    }
    
    NSInteger col = [tableTranslations columnWithIdentifier:lang.isoLangCode];
    
    [tableTranslations reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row] columnIndexes:[NSIndexSet indexSetWithIndex:col]];
}

- (NSAttributedString*) inspectorTextTranslation
{
    LocalizationEditorHandler* handler = [AppDelegate appDelegate].localizationEditorHandler;
    NSInteger row = [tableTranslations selectedRow];
    
    if (row == -1) return NULL;
    
    LocalizationEditorTranslation* translation = [handler.translations objectAtIndex:row];
    LocalizationEditorLanguage* lang = [self selectedLanguage];
    NSString* translationStr = [translation.translations objectForKey:lang.isoLangCode];
    
    if (!translationStr) return NULL;
    return [[NSAttributedString alloc] initWithString:translationStr];
}

#pragma mark Table View data provider

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    LocalizationEditorHandler* handler = [AppDelegate appDelegate].localizationEditorHandler;
    
    if (aTableView == tableLanguages)
    {
        return handler.activeLanguages.count;
    }
    else if (aTableView == tableTranslations)
    {
        return handler.translations.count;
    }
    
    return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    LocalizationEditorHandler* handler = [AppDelegate appDelegate].localizationEditorHandler;
    
    if (aTableView == tableLanguages)
    {
        if ([aTableColumn.identifier isEqualToString:@"enabled"])
        {
            LocalizationEditorLanguage* lang = [handler.activeLanguages objectAtIndex:rowIndex];
            return [NSNumber numberWithBool:lang.quickEdit];
        }
        else if ([aTableColumn.identifier isEqualToString:@"name"])
        {
            LocalizationEditorLanguage* lang = [handler.activeLanguages objectAtIndex:rowIndex];
            return lang.name;
        }
    }
    else if (aTableView == tableTranslations)
    {
        LocalizationEditorTranslation* translation = [handler.translations objectAtIndex:rowIndex];
        
        if ([aTableColumn.identifier isEqualToString:@"key"])
        {
            return translation.key;
        }
        else if ([aTableColumn.identifier isEqualToString:@"comment"])
        {
            return translation.comment;
        }
        else if ([aTableColumn.identifier isEqualToString:@"warning"])
        {
            if ([translation hasTranslationsForLanguages:handler.activeLanguages])
            {
                // All languages are covered
                return NULL;
            }
            else
            {
                // Some language is missing
                return [NSImage imageNamed:@"editor-warning.png"];
            }
        }
        else
        {
            if(translation.languagesDownloading &&
               ((ProjectSettings*)[AppDelegate appDelegate].projectSettings).isDownloadingTranslations &&
               [translation.languagesDownloading containsObject:aTableColumn.identifier])
            {
                [[aTableColumn dataCellForRow:rowIndex] setEnabled:0];
                return @"Downloading...";
            }
            else
            {
                [[aTableColumn dataCellForRow:rowIndex] setEnabled:1];
                return [translation.translations objectForKey:aTableColumn.identifier];
            }
        }
    }
    
    return NULL;
}

/*
 * If a translation is updated, update the tableView in the translation window if there
 * is one open.
 */
- (void) tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    LocalizationEditorHandler* handler = [AppDelegate appDelegate].localizationEditorHandler;
    
    if (tableView == tableLanguages)
    {
        if ([tableColumn.identifier isEqualToString:@"enabled"])
        {
            LocalizationEditorLanguage* lang = [handler.activeLanguages objectAtIndex:row];
            lang.quickEdit = [object boolValue];
            [self updateQuickEditLangs];
        }
    }
    else if (tableView == tableTranslations)
    {
        LocalizationEditorTranslation* translation = [handler.translations objectAtIndex:row];
        
        if ([tableColumn.identifier isEqualToString:@"key"])
        {
            if (translation.key == NULL && (object == NULL || [object isEqualToString:@""]))
            {
                // This is a new entry without a key, remove it
                [handler.translations removeObject:translation];
                [tableTranslations reloadData];
                [handler setEdited];
            }
            else if (object != NULL && ![object isEqualToString:@""])
            {
                if (![handler isValidKey:object forTranslation:translation])
                {
                    // This is a duplicate key
                    NSBeep();
                    
                    if (translation.key == NULL)
                    {
                        // Key hasn't been set yet, select it again so user can edit
                        [tableTranslations editColumn:1 row:row withEvent:NULL select:YES];
                    }
                }
                else
                {
                    // All is good change the key
                    translation.key = object;
                    [handler setEdited];
                }
            }
            
        }
        else if ([tableColumn.identifier isEqualToString:@"comment"])
        {
            translation.comment = object;
            [handler setEdited];
        }
        else
        {
            if ([object isKindOfClass:[NSString class]])
            {
                NSString* lang = tableColumn.identifier;
                
                [translation.translations setObject:object forKey:lang];
                [tableTranslations reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
                [handler setEdited];
            }
        }
        
        [self updateInspector];
    }
}

#pragma mark Drag and drop

- (id < NSPasteboardWriting >)tableView:(NSTableView *)tableView pasteboardWriterForRow:(NSInteger)row
{
    if (tableView == tableTranslations)
    {
        LocalizationEditorHandler* handler = [AppDelegate appDelegate].localizationEditorHandler;
        return [handler.translations objectAtIndex:row];
    }
    return NULL;
}

- (NSDragOperation)tableView:(NSTableView *)aTableView validateDrop:(id < NSDraggingInfo >)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation
{
    if (operation == NSTableViewDropAbove) return NSDragOperationMove;
    return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id < NSDraggingInfo >)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation
{
    if (operation == NSTableViewDropAbove)
    {
        LocalizationEditorHandler* handler = [AppDelegate appDelegate].localizationEditorHandler;
        NSPasteboard* pb = [info draggingPasteboard];
        
        NSArray* items = [pb propertyListsForType:@"com.cocosbuilder.LocalizationEditorTranslation"];
        if (items.count != 1) return NO;
        
        NSDictionary* dict = [items objectAtIndex:0];
        
        // Find source translation by key
        NSString* key = [dict objectForKey:@"key"];
        LocalizationEditorTranslation* transl = NULL;
        for (LocalizationEditorTranslation* cTransl in handler.translations)
        {
            if ([cTransl.key isEqualToString:key])
            {
                transl = cTransl;
                break;
            }
        }
        
        if (!transl) return NO;
        
        // Move translation to new index
        int oldIndex = [handler.translations indexOfObject:transl];
        int newIndex = row;
        if (newIndex >= oldIndex) newIndex--;
        
        [handler.translations removeObjectAtIndex:oldIndex];
        [handler.translations insertObject:transl atIndex:newIndex];
        
        [tableTranslations reloadData];
        [tableTranslations selectRowIndexes:[NSIndexSet indexSetWithIndex:newIndex] byExtendingSelection:NO];
        
        return YES;
    }
    return NO;
}

#pragma mark Table View delegate

- (void) tableViewSelectionDidChange:(NSNotification *)notification
{
    NSInteger row = [tableTranslations selectedRow];
    
    self.inspectorEnabled = (row != -1);
    [self updateInspector];
}

#pragma mark Inspector key text view delegate

- (BOOL)textShouldBeginEditing:(NSText *)aTextObject
{
    if (aTextObject == textInspectorKey)
    {
        self.startTextValue = [aTextObject string];
    }
    return YES;
}

- (void) textDidEndEditing:(NSNotification *)notification
{
    LocalizationEditorHandler* handler = [AppDelegate appDelegate].localizationEditorHandler;
    
    if (notification.object == textInspectorKey)
    {
        NSString* endTextValue = [self.inspectorTextKey string];
        
        if (!self.startTextValue && !endTextValue) return;
        
        if (!endTextValue || [endTextValue isEqualToString:@""])
        {
            self.inspectorTextKey = [[NSAttributedString alloc] initWithString:self.startTextValue];
            return;
        }
        
        // Check for duplicates
        NSInteger row = [tableTranslations selectedRow];
        LocalizationEditorTranslation* transl = [handler.translations objectAtIndex:row];
        
        if (![handler isValidKey:endTextValue forTranslation:transl])
        {
            // Revert to old value
            NSBeep();
            self.inspectorTextKey = [[NSAttributedString alloc] initWithString:self.startTextValue];
            return;
        }
        
        [handler setEdited];
    }
    else
    {
        [handler setEdited];
    }
    
}

#pragma mark Split view delegate

- (CGFloat) splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex
{
    if (proposedMinimumPosition < 300) return 300;
    else return proposedMinimumPosition;
}

- (CGFloat) splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMaximumPosition ofSubviewAt:(NSInteger)dividerIndex
{
    float max = splitView.frame.size.height - 40;
    if (proposedMaximumPosition > max) return max;
    else return proposedMaximumPosition;
}

/*
 * This replaces the bindings of before. If 'has open file' changes, change the language window according to the 'isDownloading' status of the
 * new project. 
 */
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    ProjectSettings* ps = [AppDelegate appDelegate].projectSettings;
    if([keyPath isEqualToString:@"hasOpenFile"]){
        if(ps.isDownloadingTranslations)
        {
            _ltw = [[LocalizationTranslateWindow alloc] initWithDownload:ps.latestRequestID parentWindow:self numToDownload:ps.numToDownload];
            [_ltw restartDownload];
            [self setDownloadingTranslations];
        }else{
            [_ltw pauseDownload];
            [self finishDownloadingTranslations];
            _ltw = nil;
        }
    }
    
}
@end
