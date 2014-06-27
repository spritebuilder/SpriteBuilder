#import <Foundation/Foundation.h>
#import "PublishFileLookupProtocol.h"

@interface PublishRenamedFilesLookup : NSObject  <PublishFileLookupProtocol>

- (id)initWithFlattenPaths:(BOOL)flattenPaths;

- (void)addRenamingRuleFrom:(NSString *)src to:(NSString *)dst;

- (BOOL)writeToFileAtomically:(NSString *)filePath;

- (void)addIntermediateLookupPath:(NSString *)filePath;

@end