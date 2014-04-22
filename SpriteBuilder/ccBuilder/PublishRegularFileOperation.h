#import <Foundation/Foundation.h>


@interface PublishRegularFileOperation : NSOperation

@property (nonatomic, copy) NSString *srcFilePath;
@property (nonatomic, copy) NSString *dstFilePath;

- (instancetype)initWithSrcFilePath:(NSString *)srcFilePath dstFilePath:(NSString *)dstFilePath;

@end