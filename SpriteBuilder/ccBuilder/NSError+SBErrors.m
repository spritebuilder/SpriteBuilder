#import "NSError+SBErrors.h"
#import "SBErrors.h"


@implementation NSError (SBErrors)

+ (void)setNewErrorWithCode:(NSError **)errorPtr code:(NSInteger)code userInfo:(NSDictionary *)userInfo;
{
    NSError *newError = [NSError errorWithDomain:SBErrorDomain
                                            code:code
                                        userInfo:userInfo];

    [NSError setError:errorPtr withError:newError];
}

+ (void)setNewErrorWithCode:(NSError **)errorPtr code:(NSInteger)code message:(NSString *)message
{
    [NSError setNewErrorWithCode:errorPtr code:code userInfo:@{NSLocalizedDescriptionKey : message}];
}

+ (void)setError:(NSError **)errorPtr withError:(NSError *)error
{
    if (errorPtr)
    {
        *errorPtr = error;
    }
}

@end