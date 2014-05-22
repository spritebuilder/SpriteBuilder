#import <Foundation/Foundation.h>
#import "PackageCreateDelegate.h"


@interface PackageCreator : NSObject <PackageCreateDelegate>

- (instancetype)initWithWindow:(NSWindow *)window;

- (void)showCreateNewPackageDialog;

@end