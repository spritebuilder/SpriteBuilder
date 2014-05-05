#import <Foundation/Foundation.h>
#import "PublishBaseOperation.h"

@interface PublishGeneratedFilesOperation : PublishBaseOperation
{

}

@property (nonatomic) int targetType;
@property (nonatomic, copy) NSString *outputDir;
@property (nonatomic, strong) NSMutableSet *publishedResources;
@property (nonatomic, strong) NSMutableDictionary *renamedFiles;
@property (nonatomic, strong) NSMutableSet *publishedSpriteSheetFiles;

@end