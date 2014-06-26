#import <Foundation/Foundation.h>

// TODO: Move to it's own file after cherry picking
@protocol PublishFileLookupProtocol <NSObject>

- (void)addRenamingRuleFrom:(NSString *)src to:(NSString *)dst;

@end


#pragma mark -----------------------------------------------------------------------------

// TODO: Move to it's own file after cherry picking
@interface PublishIntermediateFilesLookup : NSObject <PublishFileLookupProtocol>

- (instancetype)initWithFlattenPaths:(BOOL)flattenPaths;

- (BOOL)writeToFile:(NSString *)path;

@end


#pragma mark -----------------------------------------------------------------------------

@interface PublishRenamedFilesLookup : NSObject  <PublishFileLookupProtocol>

- (id)initWithFlattenPaths:(BOOL)flattenPaths;

- (void)addRenamingRuleFrom:(NSString *)src to:(NSString *)dst;

- (BOOL)writeToFileAtomically:(NSString *)filePath;

- (void)addIntermediateLookupPath:(NSString *)filePath;

@end