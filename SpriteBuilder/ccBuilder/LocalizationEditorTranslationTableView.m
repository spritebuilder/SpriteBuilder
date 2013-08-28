//
//  LocalizationEditorTranslationTableView.m
//  SpriteBuilder
//
//  Created by Viktor on 8/7/13.
//
//

#import "LocalizationEditorTranslationTableView.h"
#import "AppDelegate.h"
#import "LocalizationEditorHandler.h"
#import "LocalizationEditorWindow.h"

@implementation LocalizationEditorTranslationTableView

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
        NSAlert* alert = [NSAlert alertWithMessageText:@"Are you sure you want to delete the selected translation?" defaultButton:@"Cancel" alternateButton:@"Delete" otherButton:NULL informativeTextWithFormat:@"If it is used in interface files translations may be broken."];
        NSInteger result = [alert runModal];
        
        if (result == NSAlertDefaultReturn)
        {
            return;
        }
        
        [[AppDelegate appDelegate].localizationEditorHandler.windowController removeTranslationsAtIndexes:[self selectedRowIndexes]];
        
        return;
    }
    
    [super keyDown:theEvent];
}

@end
