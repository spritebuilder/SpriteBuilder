#import "cocos2d.h"

@class PathObject;
@class RegionObject;
@interface GeometryUtil: NSObject {
	
}

+ (BOOL) pointInRegion:(CGPoint)pt poly: (NSArray *)polygon;

@end
