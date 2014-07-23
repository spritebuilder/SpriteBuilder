#import <Foundation/Foundation.h>
#import "FileCommandProtocol.h"

@interface CreateDirectoryFileCommand : NSObject <FileCommandProtocol>

@property (nonatomic, copy) NSString *dirPath;

- (instancetype)initWithDirPath:(NSString *)dirPath;

@end