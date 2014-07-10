#import <Foundation/Foundation.h>

#import "ResourceCommandProtocol.h"

@class ProjectSettings;


@interface ResourcePublishPackageCommand : NSObject <ResourceCommandProtocol, ResourceCommandContextMenuProtocol>

@property (nonatomic, strong) NSArray *resources;
@property (nonatomic, copy) NSString *publishDirectory;
@property (nonatomic, weak) ProjectSettings *projectSettings;
@property (nonatomic, weak) NSWindow *windowForModals;

@end