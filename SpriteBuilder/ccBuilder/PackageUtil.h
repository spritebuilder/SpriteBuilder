#import <Foundation/Foundation.h>

// If NO is returned the error pointer has to be set
typedef BOOL (^PackagePathBlock) (NSString *packagePath, NSError **error);

@interface PackageUtil : NSObject

// Will enumerate the given package paths and apply the block on each
// Used for package removal and importing
// If at least one block returns NO the error pointer will be set to an
//    NSError object with the given prevailingErrorCode as code and errorDescription as localized description
// Will return NO as soon as one block invocation returns NO, this won't
//    stop the enumeration
// If NO is returned refer to the userInfo dictionary with the key @"errors" to get a list of the underlying
//    errors
- (BOOL)enumeratePackagePaths:(NSArray *)packagePaths
                        error:(NSError **)error
          prevailingErrorCode:(NSInteger)prevailingErrorCode
             errorDescription:(NSString *)errorDescription
                        block:(PackagePathBlock)block;

@end