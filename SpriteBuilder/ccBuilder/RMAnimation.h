#import <Foundation/Foundation.h>


@interface RMAnimation : NSObject
{
    NSString *animationFile;
    NSString *animationName;
}

@property (nonatomic, copy) NSString *animationFile;
@property (nonatomic, copy) NSString *animationName;

@end
