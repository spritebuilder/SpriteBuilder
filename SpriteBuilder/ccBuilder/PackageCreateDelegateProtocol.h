#import <Foundation/Foundation.h>

@protocol PackageCreateDelegateProtocol <NSObject>

- (BOOL)createPackageWithName:(NSString *)packageName error:(NSError **)error;

- (BOOL)importPackageWithName:(NSString *)packageName error:(NSError **)error;
- (BOOL)importPackageWithPath:(NSString *)packagePath error:(NSError **)error;

- (BOOL)removePackagesFromProject:(NSArray *)packagePaths error:(NSError **)error;

@end