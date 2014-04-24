#import <Foundation/Foundation.h>
#import "PublishBaseOperation.h"

@class CCBWarnings;
@class AppDelegate;

@interface OptimizeImageWithOptiPNGOperation : PublishBaseOperation

@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, copy) NSString *optiPngPath;
@property (nonatomic, weak) CCBWarnings *warnings;
@property (nonatomic, weak) AppDelegate *appDelegate;
@property (nonatomic, strong) NSTask *task;

@end