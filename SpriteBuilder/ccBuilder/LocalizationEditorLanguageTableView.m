//
//  LocalizationEditorLanguageTableView.m
//  SpriteBuilder
//
//  Created by Viktor on 8/7/13.
//
//

#import "LocalizationEditorLanguageTableView.h"
#import "AppDelegate.h"
#import "LocalizationEditorHandler.h"
#import "LocalizationEditorWindow.h"

@implementation LocalizationEditorLanguageTableView

- (void) keyDown:(NSEvent *)theEvent
{
    unichar key = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
    if(key == NSDeleteCharacter)
    {
        if([self selectedRowIndexes].count == 0)
        {
            NSBeep();
            return;
        }
        
        // Confirm remove of items
        NSAlert* alert = [NSAlert alertWithMessageText:@"Are you sure you want to delete the selected languages?" defaultButton:@"Cancel" alternateButton:@"Delete" otherButton:NULL informativeTextWithFormat:@"You cannot undo this operation, and translations may be lost."];
        NSInteger result = [alert runModal];
        
        if (result == NSAlertDefaultReturn)
        {
            return;
        }
        
        [[AppDelegate appDelegate].localizationEditorHandler.windowController removeLanguagesAtIndexes:[self selectedRowIndexes]];
        
        return;
    }
    
    [super keyDown:theEvent];
}

@end
