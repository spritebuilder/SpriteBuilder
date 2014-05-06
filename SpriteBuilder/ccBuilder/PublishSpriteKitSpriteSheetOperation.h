#import <Foundation/Foundation.h>
#import "PublishBaseOperation.h"


@interface PublishSpriteKitSpriteSheetOperation : PublishBaseOperation

@property (nonatomic, copy) NSString *spriteSheetDir;
@property (nonatomic, copy) NSString *spriteSheetName;
@property (nonatomic, copy) NSString *subPath;
@property (nonatomic, copy) NSString *resolution;
@property (nonatomic, copy) NSString *textureAtlasToolFilePath;

@end