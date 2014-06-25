#import <Foundation/Foundation.h>

@interface MoveFileCommand : NSObject

@property (nonatomic, copy) NSString *fromPath;
@property (nonatomic, copy) NSString *toPath;

@property (nonatomic, readonly) BOOL successful;
@property (nonatomic, strong, readonly) NSError *error;

- (instancetype)initWithFromPath:(NSString *)fromPath toPath:(NSString *)toPath;

- (BOOL)execute:(NSError **)error;

- (BOOL)undo:(NSError **)error;

@end