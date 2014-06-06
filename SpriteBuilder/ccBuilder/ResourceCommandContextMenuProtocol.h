#import <Foundation/Foundation.h>

@protocol ResourceCommandContextMenuProtocol <NSObject>

+ (NSString *)nameForResources:(NSArray *)resources;

+ (BOOL)isValidForSelectedResources:(NSArray *)resources;

@end