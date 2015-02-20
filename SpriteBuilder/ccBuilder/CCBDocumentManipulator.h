//
// Created by Nicky Weber on 20.02.15.
//

#import <Foundation/Foundation.h>

typedef NSDictionary *(^PropertyReplacerBlock)(NSDictionary *property, NSDictionary *child);

@interface CCBDocumentManipulator : NSObject

@property (nonatomic, strong, readonly) NSMutableDictionary *document;

- (instancetype)initWithDocument:(NSMutableDictionary *)document;

- (void)processAllProperties:(PropertyReplacerBlock)propertyReplacerBlock;

@end