#import "PackageUtil.h"
#import "NotificationNames.h"
#import "NSError+SBErrors.h"


@implementation PackageUtil

- (BOOL)enumeratePackagePaths:(NSArray *)packagePaths
                        error:(NSError **)error
          prevailingErrorCode:(NSInteger)prevailingErrorCode
             errorDescription:(NSString *)errorDescription
                        block:(PackagePathBlock)block
{
    if (!packagePaths || packagePaths.count <= 0)
    {
        return YES;
    }

    BOOL result = YES;
    NSUInteger packagesAltered = 0;
    NSMutableArray *errors = [NSMutableArray array];

    for (NSString *packagePath in packagePaths)
    {
        NSError *anError;
        if (!block(packagePath, &anError))
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
        [NSError setNewErrorWithCode:error code:prevailingErrorCode userInfo:@{NSLocalizedDescriptionKey : errorDescription, @"errors" : errors}];
    }

    return result;
}

@end