#import <Foundation/Foundation.h>
#import "PublishBaseOperation.h"


@class CCBWarnings;
@class AppDelegate;
@class ProjectSettings;

@interface PublishSpriteSheetOperation : PublishBaseOperation

@property (nonatomic, copy) NSString *spriteSheetFile;
@property (nonatomic) int targetType;

@property (nonatomic, copy) NSString *subPath;
@property (nonatomic, strong) NSArray *srcDirs;
@property (nonatomic, copy) NSString *resolution;
@property (nonatomic, copy) NSDate *srcSpriteSheetDate;
@property (nonatomic, copy) NSString *publishDirectory;
@property (nonatomic, strong) NSMutableSet *publishedPNGFiles;
@property (nonatomic, strong) NSMutableArray *publishedSpriteSheetNames;

@property (nonatomic, weak) AppDelegate *appDelegate;

@end
