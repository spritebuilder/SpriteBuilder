#import <Foundation/Foundation.h>


@class CCBWarnings;
@class AppDelegate;
@class ProjectSettings;

@interface PublishSpriteSheetOperation : NSOperation

- (instancetype)initWithAppDelegate:(AppDelegate *)appDelegate warnings:(CCBWarnings *)warnings projectSettings:(ProjectSettings *)projectSettings;

@property (nonatomic, copy) NSString *spriteSheetFile;
@property (nonatomic) int targetType;

@property (nonatomic, copy) NSString *subPath;
@property (nonatomic, strong) NSArray *srcDirs;
@property (nonatomic, copy) NSString *resolution;
@property (nonatomic, copy) NSDate *srcSpriteSheetDate;
@property (nonatomic, copy) NSString *publishDirectory;
@property (nonatomic, strong) NSMutableSet *publishedPNGFiles;
@property (nonatomic, strong) NSMutableArray *publishedSpriteSheetNames;

@end