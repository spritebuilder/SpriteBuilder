#import <Foundation/Foundation.h>

#import "ResourceCommandProtocol.h"
#import "ResourceCommandContextMenuProtocol.h"

@class ProjectSettings;
@class ResourceManagerOutlineView;
@class ResourceManager;

@interface ResourceDeleteCommand : NSObject <ResourceCommandProtocol, ResourceCommandContextMenuProtocol>

@property (nonatomic, strong) NSArray *resources;
@property (nonatomic, strong) ProjectSettings *projectSettings;
@property (nonatomic, weak) NSOutlineView *outlineView;
@property (nonatomic, strong) ResourceManager *resourceManager;

@end