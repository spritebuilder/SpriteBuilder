#import <Foundation/Foundation.h>

@class ResourceActionController;


@interface ResourceContextMenu : NSMenu

@property (nonatomic, strong, readonly) NSArray *resources;

- (instancetype)initWithActionTarget:(id)actionTarget resources:(NSArray *)resources;

@end