#import <Foundation/Foundation.h>
#import "FileCommandProtocol.h"

@interface MoveFileCommand : NSObject <FileCommandProtocol>

@property (nonatomic, copy) NSString *fromPath;
@property (nonatomic, copy) NSString *toPath;

- (instancetype)initWithFromPath:(NSString *)fromPath toPath:(NSString *)toPath;

@end