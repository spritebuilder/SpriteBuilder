//
//  LocalizationEditorHandler.h
//  SpriteBuilder
//
//  Created by Viktor on 8/6/13.
//
//

#import <Foundation/Foundation.h>
@class LocalizationEditorWindow;

@interface LocalizationEditorHandler : NSObject
{
    NSMutableArray* languages;
    LocalizationEditorWindow* windowController;
}

@property (nonatomic,readonly) NSMutableArray* languages;
@end
