#import <Foundation/Foundation.h>

@protocol PackageCreateDelegateProtocol;
@class ProjectSettings;


@interface PackageController : NSObject <PackageCreateDelegateProtocol>


@property (nonatomic, strong) ProjectSettings *projectSettings;

- (void)showCreateNewPackageDialogForWindow:(NSWindow *)window;

- (void)importPackage:(NSString *)packagePath;

@end