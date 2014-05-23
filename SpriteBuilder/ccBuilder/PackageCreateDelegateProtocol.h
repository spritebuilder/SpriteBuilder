#import <Foundation/Foundation.h>

@protocol PackageCreateDelegateProtocol <NSObject>

- (BOOL)createPackageWithName:(NSString *)packageName error:(NSError **)error;

@end