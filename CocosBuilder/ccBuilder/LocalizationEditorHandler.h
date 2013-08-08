//
//  LocalizationEditorHandler.h
//  SpriteBuilder
//
//  Created by Viktor on 8/6/13.
//
//

#define kCCBTranslationFileFormatVersion 1

#import <Foundation/Foundation.h>
@class LocalizationEditorWindow;
@class LocalizationEditorLanguage;
@class LocalizationEditorTranslation;

@interface LocalizationEditorHandler : NSObject
{
    NSMutableArray* languages;
    NSMutableArray* activeLanguages;
    NSMutableArray* translations;
    NSString* managedFile;
    
    LocalizationEditorWindow* windowController;
}

@property (nonatomic,readonly) NSMutableArray* languages;
@property (nonatomic,readonly) NSMutableArray* activeLanguages;
@property (nonatomic,readonly) NSMutableArray* translations;
@property (nonatomic,readonly) LocalizationEditorWindow* windowController;
@property (nonatomic,copy) NSString* managedFile;

- (BOOL) isValidKey:(NSString*) key forTranslation:(LocalizationEditorTranslation*) transl;
- (LocalizationEditorLanguage*) getLanguageByName:(NSString*)name;
- (LocalizationEditorLanguage*) getLanguageByIsoLangCode:(NSString*)code;
- (void) addActiveLanguage:(LocalizationEditorLanguage*) lang;
- (void) removeActiveLangage:(LocalizationEditorLanguage*) lang;
- (void) setEdited;

@end
