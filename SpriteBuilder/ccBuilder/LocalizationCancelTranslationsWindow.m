//
//  LocalizationCancelTranslationsWindow.m
//  SpriteBuilder
//
//  Created by Benjamin Koatz on 6/25/14.
//
//

#import "LocalizationCancelTranslationsWindow.h"
#import "LocalizationEditorWindow.h"
#import "LocalizationTranslateWindow.h"

@implementation LocalizationCancelTranslationsWindow
@synthesize editorWindow = _editorWindow;
@synthesize translateWindow = _translateWindow;

- (IBAction)yes:(id)sender {
    [_editorWindow finishDownloadingTranslations];
    [_translateWindow cancelDownload];
}

- (IBAction)no:(id)sender {
    [NSApp endSheet:self.window];
    [self.window orderOut:nil];
}
@end
