#import <Foundation/Foundation.h>

@class ResourceActionController;


@interface ResourceContextMenu : NSMenu

@property (nonatomic, strong, readonly) id resource;
@property (nonatomic, strong, readonly) NSArray *resources;

- (instancetype)initWithResource:(id)resource actionTarget:(id)actionTarget resources:(NSArray *)resources;

@end