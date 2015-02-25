//
// Created by Nicky Weber on 20.02.15.
//

#import <Foundation/Foundation.h>
#import "MigratorProtocol.h"
#import "CCRenderer_Private.h"

@class CCBDocument;


@interface CCBToSBRenameMigrator : NSObject <MigratorProtocol>


// Renames all ccb files found in filePath. CCB files are searched for recursively if filePath is a directory
// otherwise it is treated as a file.
- (instancetype)initWithFilePath:(NSString *)filePath;

// Renames all ccb files found in filePath. CCB files are searched for recursively if filePath is a directory
// otherwise it is treated as a file. RenameResult contains the occured renamings with renameResult[originalPath] = newPath
- (instancetype)initWithFilePath:(NSString *)filePath renameResult:(NSMutableDictionary *)renameResult;

@end