#import <Foundation/Foundation.h>
#import "PackageCreateDelegate.h"

@class ProjectSettings;


@interface PackageCreator : NSObject <PackageCreateDelegate>

@property (nonatomic, strong) ProjectSettings *projectSettings;

- (instancetype)initWithWindow:(NSWindow *)window;

- (void)showCreateNewPackageDialog;

@end