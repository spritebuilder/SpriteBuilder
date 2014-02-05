//
//  BayazitDecomposition.h
//  TestApp
//
//  Created by John Twigg on 2/4/14.
//  Copyright (c) 2014 John Twigg. All rights reserved.
//

// Convex decomposition algorithm created by Mark Bayazit (http://mnbayazit.com/)


@interface Bayazit : NSObject



//Decomps an input poly into convex sub polys.
//Return TRUE if operation was successful.
//return FALSE if failure. Failure cases can be caused by intersecting segments.
+(BOOL)decomposition:(NSArray *)inputPoly outputPoly:(NSArray **)outputPolys;


//Does the poly possess any intersecting line segments.
//outSegments array is [ seg1.A, seg1.B, seg2.A, seg2.B, ...]
+(BOOL)intersectingLines:(NSArray*)inputPoly outputSegments:(NSArray**)outSegments;

@end


