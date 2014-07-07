#import <Foundation/Foundation.h>
#import "PublishFileLookupProtocol.h"


@interface PublishIntermediateFilesLookup : NSObject <PublishFileLookupProtocol>

- (instancetype)initWithFlattenPaths:(BOOL)flattenPaths;

- (BOOL)writeToFile:(NSString *)path;

@end