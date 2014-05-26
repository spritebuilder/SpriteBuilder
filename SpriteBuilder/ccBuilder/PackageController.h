#import <Foundation/Foundation.h>

@protocol PackageCreateDelegateProtocol;
@class ProjectSettings;


@interface PackageController : NSObject <PackageCreateDelegateProtocol>

@property (nonatomic, strong) ProjectSettings *projectSettings;

- (void)showCreateNewPackageDialogForWindow:(NSWindow *)window;


#pragma mark - PackageCreateDelegateProtocol

- (BOOL)createPackageWithName:(NSString *)packageName error:(NSError **)error;

- (BOOL)importPackageWithName:(NSString *)packageName error:(NSError **)error;
- (BOOL)importPackageWithPath:(NSString *)packagePath error:(NSError **)error;
- (BOOL)importPackagesWithPaths:(NSArray *)packagePaths error:(NSError **)error;


@end