#import <Foundation/Foundation.h>


@interface PublishRenamedFilesLookup : NSObject

- (id)initWithFlattenPaths:(BOOL)flattenPaths;

- (void)addRenamingRuleFrom:(NSString *)src to:(NSString *)dst;

- (BOOL)writeToFileAtomically:(NSString *)filePath;

@end