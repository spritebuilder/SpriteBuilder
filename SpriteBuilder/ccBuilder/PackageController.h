#import <Foundation/Foundation.h>

@protocol PackageCreateDelegateProtocol;
@class ProjectSettings;


@interface PackageController : NSObject <PackageCreateDelegateProtocol>


@property (nonatomic, strong) ProjectSettings *projectSettings;

- (instancetype)initWithWindow:(NSWindow *)window;

- (void)showCreateNewPackageDialog;

- (void)importPackage:(NSString *)packagePath;

@end