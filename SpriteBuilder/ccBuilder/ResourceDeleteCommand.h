#import <Foundation/Foundation.h>

#import "ResourceCommandProtocol.h"
#import "ResourceCommandContextMenuProtocol.h"

@class ProjectSettings;
@class ResourceManagerOutlineView;

@interface ResourceDeleteCommand : NSObject <ResourceCommandProtocol, ResourceCommandContextMenuProtocol>

@property (nonatomic, strong) NSArray *resources;
@property (nonatomic, weak) ProjectSettings *projectSettings;
@property (nonatomic, weak) NSOutlineView *outlineView;

@end