#import <Foundation/Foundation.h>

@protocol PackageCreateDelegate <NSObject>

- (BOOL)canCreatePackageWithName:(NSString *)packageName error:(NSError **)error;

@end