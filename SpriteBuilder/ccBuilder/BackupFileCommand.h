//
// Created by Nicky Weber on 11.02.15.
//

#import <Foundation/Foundation.h>
#import "FileCommandProtocol.h"


/*

 Copies a given filePath to an automatically generated backupFilePath.

 WARNING: Undo will remove the filePath and renames the backup back to filePath

 Execute and undo cannot be performend twice. Undo cannot be performed before execution.

 Check the state properties executed and undone.

 */

@interface BackupFileCommand : NSObject <FileCommandProtocol>

@property (nonatomic, copy, readonly) NSString *filePath;
@property (nonatomic, copy, readonly) NSString *backupFilePath;

@property (nonatomic, readonly) BOOL executed;
@property (nonatomic, readonly) BOOL undone;

- (instancetype)initWithFilePath:(NSString *)filePath;

@end
