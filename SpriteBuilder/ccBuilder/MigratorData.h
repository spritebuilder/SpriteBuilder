//
// Created by Nicky Weber on 26.02.15.
//

#import <Foundation/Foundation.h>


@interface MigratorData : NSObject

@property (nonatomic, copy) NSString *originalProjectSettingsPath;
@property (nonatomic, copy) NSString *projectSettingsPath;
@property (nonatomic, strong) NSMutableDictionary *renamedFiles;
@property (nonatomic, copy, readonly) NSString *projectPath;

- (instancetype)initWithProjectSettingsPath:(NSString *)projectSettingsPath;

@end