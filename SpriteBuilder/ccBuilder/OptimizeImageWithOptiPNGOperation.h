#import <Foundation/Foundation.h>

@class CCBWarnings;
@class AppDelegate;

@interface OptimizeImageWithOptiPNGOperation : NSOperation

- (instancetype)initWithFilePath:(NSString *)filePath
                     optiPngPath:(NSString *)optiPngPath
                        warnings:(CCBWarnings *)warnings
                     appDelegate:(AppDelegate *)appDelegate;

@end