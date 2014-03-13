#import "cocos2d.h"

@class PathObject;
@class RegionObject;
@interface GeometryUtil: NSObject {
	
}

+(float)distanceFromLineSegment:(CGPoint) a b:(CGPoint)b c:(CGPoint)c;
+ (BOOL) pointInRegion:(CGPoint)pt poly: (NSArray *)polygon;

@end
