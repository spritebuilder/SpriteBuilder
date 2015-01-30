#import "PackageUtil.h"
#import "NotificationNames.h"
#import "NSError+SBErrors.h"
#import "RMPackage.h"


@implementation PackageUtil

- (BOOL)enumeratePackages:(NSArray *)packages
                    error:(NSError **)error
      prevailingErrorCode:(NSInteger)prevailingErrorCode
         errorDescription:(NSString *)errorDescription
                    block:(PackagePathBlock)block
{
    if (!packages || packages.count <= 0)
    {
        return YES;
    }

    BOOL result = YES;
    NSUInteger packagesAltered = 0;
    NSMutableArray *errors = [NSMutableArray array];

    for (RMPackage *package in packages)
    {
        NSError *anError;
        if (!block(package, &anError))
        {
            [errors addObject:anError];
            result = NO;
        }
        else
        {
            packagesAltered++;
        }
    }

    if (errors.count > 0)
    {
        [NSError setNewErrorWithErrorPointer:error code:prevailingErrorCode userInfo:@{NSLocalizedDescriptionKey : errorDescription, @"errors" : errors}];
    }

    return result;
}

@end