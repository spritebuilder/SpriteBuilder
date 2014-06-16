#import <Foundation/Foundation.h>


typedef BOOL (^PackageManipulationBlock) (NSString *packagePath, NSError **error);

@interface PackageUtil : NSObject


- (BOOL)applyProjectSettingBlockForPackagePaths:(NSArray *)packagePaths
                                          error:(NSError **)error
                            prevailingErrorCode:(NSInteger)prevailingErrorCode
                               errorDescription:(NSString *)errorDescription
                                          block:(PackageManipulationBlock)block;

@end