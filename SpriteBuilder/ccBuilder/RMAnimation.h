#import <Foundation/Foundation.h>
#import "RMResourceBase.h"


@interface RMAnimation : RMResourceBase
{
    NSString *animationFile;
    NSString *animationName;
}

@property (nonatomic, copy) NSString *animationFile;
@property (nonatomic, copy) NSString *animationName;

@end
