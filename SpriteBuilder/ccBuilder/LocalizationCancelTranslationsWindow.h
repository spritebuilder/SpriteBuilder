//
//  LocalizationCancelTranslationsWindow.h
//  SpriteBuilder
//
//  Created by Benjamin Koatz on 6/25/14.
//
//

#import <Foundation/Foundation.h>
@class LocalizationEditorWindow;
@class LocalizationTranslateWindow;

@interface LocalizationCancelTranslationsWindow : NSWindowController{
    LocalizationEditorWindow* _editorWindow;
    LocalizationTranslateWindow* _translateWindow;
}

@property (nonatomic,strong) LocalizationTranslateWindow* translateWindow;
@property (nonatomic,strong) LocalizationEditorWindow* editorWindow;
- (IBAction)yes:(id)sender;
- (IBAction)no:(id)sender;

@end
