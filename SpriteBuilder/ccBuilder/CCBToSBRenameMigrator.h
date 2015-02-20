//
// Created by Nicky Weber on 20.02.15.
//

#import <Foundation/Foundation.h>
#import "MigratorProtocol.h"
#import "CCRenderer_Private.h"


@interface CCBToSBRenameMigrator : NSObject <MigratorProtocol>

- (id)initWithDirPath:(NSString *)dirPath;

@end