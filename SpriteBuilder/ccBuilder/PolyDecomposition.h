//
//  BayazitDecomposition.h
//  TestApp
//
//  Created by John Twigg on 2/4/14.
//  Copyright (c) 2014 John Twigg. All rights reserved.
//



static const double kMinimumAcuteAngle = 5.0; //degrees

@interface PolyDecomposition : NSObject
//Decomps an input poly into convex sub polys.
//Convex decomposition algorithm created by Mark Bayazit (http://mnbayazit.com/)
//Return TRUE if operation was successful.
//return FALSE if failure. Failure cases can be caused by intersecting segments or Acute Lines.
+(BOOL)bayazitDecomposition:(NSArray *)inputPoly outputPoly:(NSArray **)outputPolys;

//Does the poly possess any intersecting line segments.
//outSegments array is [ seg1.A, seg1.B, seg2.A, seg2.B, ...]
+(BOOL)intersectingLines:(NSArray*)inputPoly outputSegments:(NSArray**)outSegments;


//Does the poly have any acute corner angles below the minimum acceptable.
//returns TRUE is there are acute lines.
//outSegments = [ pt1,pt2, pt3, ...] where (pt2-pt2) & (pt3 - pt2) form an acute angle < min.
+(BOOL)acuteCorners:(NSArray*)inputPoly outputSegments:(NSArray**)outSegments;

//turns a poly shape into a convex hull.
+(NSArray*)makeConvexHull:(NSArray*)inputPoly;

@end


