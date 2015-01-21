//
// Created by Nicky Weber on 21.01.15.
//

#import <Foundation/Foundation.h>


@interface CCBMigrator : NSObject

- (instancetype)initWithCCB:(NSDictionary *)ccb;

- (BOOL)migrate:(NSError **)error;

- (BOOL)needsMigration;

- (void)rollback;

@end
