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
    NSMutableArray* translations;
    
    LocalizationEditorWindow* windowController;
}

@property (nonatomic,readonly) NSMutableArray* languages;
@property (nonatomic,readonly) NSMutableArray* activeLanguages;
@property (nonatomic,readonly) NSMutableArray* translations;

- (LocalizationEditorLanguage*) getLanguageByName:(NSString*)name;
- (void) addActiveLanguage:(LocalizationEditorLanguage*) lang;
- (void) removeActiveLangage:(LocalizationEditorLanguage*) lang;

@end
