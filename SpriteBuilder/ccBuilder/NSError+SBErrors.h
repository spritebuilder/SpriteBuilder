#import <Foundation/Foundation.h>

@interface NSError (SBErrors)

+ (void)setNewErrorWithErrorPointer:(NSError **)errorPtr code:(NSInteger)code userInfo:(NSDictionary *)userInfo;;

+ (void)setNewErrorWithErrorPointer:(NSError **)errorPtr code:(NSInteger)code message:(NSString *)message;

+ (void)setError:(NSError **)errorPtr withError:(NSError *)error;

@end