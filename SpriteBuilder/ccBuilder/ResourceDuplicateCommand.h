//
//  ResourceDuplicateCommand.h
//  SpriteBuilder
//
//  Created by Martin Walsh on 30/10/2014.
//
//

#import <Foundation/Foundation.h>

#import "ResourceCommandProtocol.h"
#import "ResourceCommandContextMenuProtocol.h"

@class ResourceManager;

@interface ResourceDuplicateCommand : NSObject <ResourceCommandProtocol, ResourceCommandContextMenuProtocol>

@property (nonatomic, strong) NSArray *resources;
@property (nonatomic, weak) ResourceManager *resourceManager;

@end
