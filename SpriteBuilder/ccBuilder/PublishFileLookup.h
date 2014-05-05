#import <Foundation/Foundation.h>


@interface PublishFileLookup : NSObject

- (id)initWithFlattenPaths:(BOOL)flattenPaths;

- (void)addRenamingRuleFrom:(NSString *)src to:(NSString *)dst;

- (BOOL)writeToFileAtomically:(NSString *)filePath;

@end