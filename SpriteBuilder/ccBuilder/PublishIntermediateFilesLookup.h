#import <Foundation/Foundation.h>
#import "PublishFileLookupProtocol.h"


@interface PublishIntermediateFilesLookup : NSObject <PublishFileLookupProtocol>

- (BOOL)writeToFile:(NSString *)path;

@end