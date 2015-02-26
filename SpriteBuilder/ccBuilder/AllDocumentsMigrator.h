//
// Created by Nicky Weber on 19.02.15.
//

#import <Foundation/Foundation.h>
#import "MigratorProtocol.h"


@interface AllDocumentsMigrator : NSObject <MigratorProtocol>

- (id)initWithDirPath:(NSString *)dirPath toVersion:(NSUInteger)toVersion;

@end