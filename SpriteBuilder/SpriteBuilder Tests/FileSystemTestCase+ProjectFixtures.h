//
// Created by Nicky Weber on 27.02.15.
//

#import <Foundation/Foundation.h>
#import "FileSystemTestCase.h"

@interface FileSystemTestCase (ProjectFixtures)

- (void)createCCBVersion4FileWithOldBlendFuncWithPath:(NSString *)path;

- (NSDictionary *)ccbVersion4WithOldBlendFunc;

- (void)createPackageSettingsVersion2WithPath:(NSString *)path;

@end