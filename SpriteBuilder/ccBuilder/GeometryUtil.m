#import "GeometryUtil.h"

@implementation GeometryUtil


+ (BOOL) pointInRegion:(CGPoint)pt poly: (NSArray *)polygon;
{
	int nCross = 0; 
	
	for (int i = 0; i < polygon.count; i++) {
		
		CGPoint p1;
		CGPoint p2;
		
        p1 = [polygon[i] pointValue];
		p2 = [polygon[(i + 1) % polygon.count] pointValue];
		
		if ( p1.y == p2.y )
			continue; 
		
		if ( pt.y < min(p1.y, p2.y))
			continue; 
		
		if ( pt.y >= max(p1.y, p2.y)) 
			continue; 
		
		double x = (double)(pt.y - p1.y) * (double)(p2.x - p1.x) / (double)(p2.y - p1.y) + p1.x; 
		
		if ( x > pt.x ) 
			nCross++;
	} 
	
	if (nCross % 2 == 1)
    {
		return YES;
	}
	else
    {
		return NO;
	}

}

@end
