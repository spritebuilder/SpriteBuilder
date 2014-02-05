//
//  BayazitDecomposition.h
//  TestApp
//
//  Created by John Twigg on 2/4/14.
//  Copyright (c) 2014 John Twigg. All rights reserved.
//

// Convex decomposition algorithm created by Mark Bayazit (http://mnbayazit.com/)


@interface Bayazit : NSObject
+(void)decomposition:(NSArray *)inputPoly outputPoly:(NSArray **)outputPolys;
@end


