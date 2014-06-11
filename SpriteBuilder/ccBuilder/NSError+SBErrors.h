#import <Foundation/Foundation.h>

@interface NSError (SBErrors)

+ (void)setNewErrorWithCode:(NSError **)errorPtr code:(NSInteger)code userInfo:(NSDictionary *)userInfo;;

+ (void)setNewErrorWithCode:(NSError **)errorPtr code:(NSInteger)code message:(NSString *)message;

+ (void)setError:(NSError **)errorPtr withError:(NSError *)error;

@end