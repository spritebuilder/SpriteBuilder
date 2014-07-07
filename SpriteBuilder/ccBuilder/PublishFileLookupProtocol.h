#import <Foundation/Foundation.h>

@protocol PublishFileLookupProtocol <NSObject>

- (void)addRenamingRuleFrom:(NSString *)src to:(NSString *)dst;

@end
