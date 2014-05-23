#import <Foundation/Foundation.h>

@protocol PackageCreateDelegateProtocol;
@class ProjectSettings;


@interface PackageCreator : NSObject <PackageCreateDelegateProtocol>


@property (nonatomic, strong) ProjectSettings *projectSettings;

- (instancetype)initWithWindow:(NSWindow *)window;

- (void)showCreateNewPackageDialog;

@end