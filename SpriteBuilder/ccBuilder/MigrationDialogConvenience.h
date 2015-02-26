//
// Created by Nicky Weber on 26.02.15.
//

#import <Foundation/Foundation.h>

@class CCBDocument;
@class ProjectSettings;


@interface MigrationDialogConvenience : NSObject

+ (ProjectSettings *)migrateWithFilePath:(NSString *)filePath;

+ (CCBDocument *)migrateDocumentWithFilePath:(NSString *)filePath
                             projectSettings:(ProjectSettings *)projectSettings;

@end