#import <Foundation/Foundation.h>

@class ResourceCommandController;


@interface ResourceContextMenu : NSMenu

@property (nonatomic, strong, readonly) NSArray *resources;

- (instancetype)initWithActionTarget:(id)actionTarget resources:(NSArray *)resources;

@end