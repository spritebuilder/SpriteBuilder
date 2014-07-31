#import <Foundation/Foundation.h>

#import "ResourceCommandContextMenuProtocol.h"

@class ProjectSettings;
@class ResourceManager;

@interface ResourceNewPackageCommand : NSObject <ResourceCommandProtocol, ResourceCommandContextMenuProtocol>

@property (nonatomic, strong) NSArray *resources;
@property (nonatomic, weak) NSOutlineView *outlineView;
@property (nonatomic, weak) ProjectSettings *projectSettings;
@property (nonatomic, weak) NSWindow *windowForModals;
@property (nonatomic, weak) ResourceManager *resourceManager;

@end