//
// Created by Nicky Weber on 09.02.15.
//

#import <Foundation/Foundation.h>


@interface PublishResolutions : NSObject <NSFastEnumeration>

@property (nonatomic) BOOL resolution_1x;
@property (nonatomic) BOOL resolution_2x;
@property (nonatomic) BOOL resolution_4x;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

- (NSDictionary *)toDictionary;

@end