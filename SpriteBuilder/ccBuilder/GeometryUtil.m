#import "GeometryUtil.h"

@implementation GeometryUtil

+(float)distanceFromLineSegment:(CGPoint) a b:(CGPoint)b c:(CGPoint)c;
{
    float ax = a.x;
    float ay = a.y;
    float bx = b.x;
    float by = b.y;
    float cx = c.x;
    float cy = c.y;
    
	float r_numerator = (cx-ax)*(bx-ax) + (cy-ay)*(by-ay);
	float r_denomenator = (bx-ax)*(bx-ax) + (by-ay)*(by-ay);
	float r = r_numerator / r_denomenator;
    
    float s = ((ay-cy)*(bx-ax)-(ax-cx)*(by-ay)) / r_denomenator;
    
    float distanceSegment = 0;
	float distanceLine = fabs(s)*sqrt(r_denomenator);
    
	if ( (r >= 0) && (r <= 1) )
	{
		distanceSegment = distanceLine;
	}
	else
	{
        
		float dist1 = (cx-ax)*(cx-ax) + (cy-ay)*(cy-ay);
		float dist2 = (cx-bx)*(cx-bx) + (cy-by)*(cy-by);
		if (dist1 < dist2)
		{
			distanceSegment = sqrtf(dist1);
		}
		else
		{
			distanceSegment = sqrtf(dist2);
		}
	}
    
	return distanceSegment;
}


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
		
		if ( pt.y < MIN(p1.y, p2.y))
			continue; 
		
		if ( pt.y >= MAX(p1.y, p2.y))
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
