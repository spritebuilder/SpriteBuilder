//
// Created by Nicky Weber on 26.01.15.
//

#import <Foundation/Foundation.h>

@protocol CCBDictionaryMigrationProtocol <NSObject>

- (NSDictionary *)migrate:(NSDictionary *)ccb error:(NSError **)error;

@end
