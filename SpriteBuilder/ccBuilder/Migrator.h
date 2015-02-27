//
// Created by Nicky Weber on 26.02.15.
//

#import <Foundation/Foundation.h>

@class CCBDocument;
@class ProjectSettings;


@interface Migrator : NSObject

+ (ProjectSettings *)migrateFullProjectWithProjectSettingsFilePath:(NSString *)filePath;

+ (CCBDocument *)migrateDocumentWithFilePath:(NSString *)filePath
                             projectSettings:(ProjectSettings *)projectSettings;

@end
