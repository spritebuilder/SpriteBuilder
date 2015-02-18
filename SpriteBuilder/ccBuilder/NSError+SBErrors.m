#import "NSError+SBErrors.h"
#import "Errors.h"


@implementation NSError (SBErrors)

+ (void)setNewErrorWithErrorPointer:(NSError **)errorPtr code:(NSInteger)code userInfo:(NSDictionary *)userInfo;
{
    NSError *newError = [NSError errorWithDomain:SBErrorDomain
                                            code:code
                                        userInfo:userInfo];

    [NSError setError:errorPtr withError:newError];
}

+ (void)setNewErrorWithErrorPointer:(NSError **)errorPtr code:(NSInteger)code message:(NSString *)message
{
    [NSError setNewErrorWithErrorPointer:errorPtr code:code userInfo:@{NSLocalizedDescriptionKey : message}];
}

+ (void)setError:(NSError **)errorPtr withError:(NSError *)error
{
    if (errorPtr)
    {
        *errorPtr = error;
    }
}

@end