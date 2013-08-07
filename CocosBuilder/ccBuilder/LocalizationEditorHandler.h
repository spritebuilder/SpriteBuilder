//
//  LocalizationEditorHandler.h
//  SpriteBuilder
//
//  Created by Viktor on 8/6/13.
//
//

#import <Foundation/Foundation.h>
@class LocalizationEditorWindow;
@class LocalizationEditorLanguage;

@interface LocalizationEditorHandler : NSObject
{
    NSMutableArray* languages;
    NSMutableArray* activeLanguages;
    LocalizationEditorWindow* windowController;
}

@property (nonatomic,readonly) NSMutableArray* languages;
@property (nonatomic,readonly) NSMutableArray* activeLanguages;

- (LocalizationEditorLanguage*) getLanguageByName:(NSString*)name;
- (void) addActiveLanguage:(LocalizationEditorLanguage*) lang;
- (void) removeActiveLangage:(LocalizationEditorLanguage*) lang;

@end
