//
//  BayazitDecomposition.mm
//  TestApp
//
//  Created by John Twigg on 2/4/14.
//  Copyright (c) 2014 John Twigg. All rights reserved.
//
// Convex decomposition algorithm created by Mark Bayazit (http://mnbayazit.com/)


#include "PolyDecomposition.h"
#include <stdlib.h>
#include <algorithm>
#include <vector>
#import "cocos2d.h"
#import "chipmunk.h"
    
typedef std::vector<CGPoint> Verticies;
typedef std::vector<Verticies> VerticiesList;

bool isReflex(const Verticies &p, const int &i);
void makeCCW(Verticies &poly);
void internalDecomposePoly(const Verticies &inputPoly, VerticiesList & outputPolys);

@implementation PolyDecomposition

+(NSArray*)makeConvexHull:(NSArray*)inputPoly
{
   int numPts = inputPoly.count;
    
    cpVect* verts = (cpVect*)malloc(sizeof(cpVect) * numPts);
    int idx = 0;
    for (NSValue* ptVal in inputPoly)
    {
        CGPoint pt = [ptVal pointValue];
        verts[idx].x = pt.x;
        verts[idx].y = pt.y;
        idx++;
    }
    
    int newNumPts = cpConvexHull(numPts, verts, verts, NULL, 0.0f);
    
    NSMutableArray* hull = [NSMutableArray array];
    for (idx = 0; idx < newNumPts; idx++)
    {
        [hull addObject:[NSValue valueWithPoint:ccp(verts[idx].x, verts[idx].y)]];
    }
    
    free(verts);
    
    return hull;
}

+(BOOL)acuteCorners:(NSArray*)inputPoly outputSegments:(NSArray**)outSegments
{
    NSMutableArray * acuteSegments = [NSMutableArray array];
    
    for (int j = 0; j < inputPoly.count; j++) {
        
        CGPoint ptA = [inputPoly[j] pointValue];
        CGPoint ptB = [inputPoly[(j + 1) % inputPoly.count] pointValue];
        CGPoint ptC = [inputPoly[(j + 2) % inputPoly.count] pointValue];
        
        CGPoint segA = ccpNormalize(ccpSub(ptA ,ptB));
        CGPoint segB = ccpNormalize(ccpSub(ptC, ptB));
        
        if(ccpDot(segA, segB) > cosf(CC_DEGREES_TO_RADIANS(kMinimumAcuteAngle)))
        {
            [acuteSegments addObject:[NSValue valueWithPoint:ptA]];
            [acuteSegments addObject:[NSValue valueWithPoint:ptB]];
            [acuteSegments addObject:[NSValue valueWithPoint:ptC]];
        }
    }
    
    if(acuteSegments.count > 0 && outSegments)
    {
        *outSegments = acuteSegments;
    }
    return acuteSegments.count > 0;
    
}

//outSegments array is [ seg1.A, seg1.B, seg2.A, seg2.B, ...]
+(BOOL)intersectingLines:(NSArray*)inputPoly outputSegments:(NSArray**)outSegments
{
    NSMutableArray * intersectingSegments = [NSMutableArray array];
    
    for (int i=0; i < inputPoly.count; i++) {
        for (int j = 0; j < inputPoly.count; j++) {
            if(i == j)
                continue;
            
            CGPoint ptA = [inputPoly[i] pointValue];
            CGPoint ptB = [inputPoly[(i + 1) % inputPoly.count] pointValue];
            
            CGPoint ptC = [inputPoly[j] pointValue];
            CGPoint ptD = [inputPoly[(j + 1) % inputPoly.count] pointValue];
            
            float S, T;
            
            if( ccpLineIntersect(ptA, ptB, ptC, ptD, &S, &T )
               && (S > 0.0f && S < 1.0f && T > 0.0f && T <= 1.0f) )
            {
                [intersectingSegments addObject:[NSValue valueWithPoint:ptA]];
                [intersectingSegments addObject:[NSValue valueWithPoint:ptB]];
            }
            
        }
    }
    
    if(intersectingSegments.count > 0)
    {
        if(outSegments)
            *outSegments = intersectingSegments;
        
        return YES;
    }
    
    return NO;
}

+(BOOL)bayazitDecomposition:(NSArray *)inputPoly outputPoly:(NSArray *__autoreleasing *)outputPolys
{
    if([PolyDecomposition intersectingLines:inputPoly outputSegments:nil])
    {
        return NO;
    }
    
    if([PolyDecomposition acuteCorners:inputPoly outputSegments:nil])
    {
        return NO;
    }
       
    Verticies workingPoly;
    for (int i=0; i < inputPoly.count; i++) {
        NSValue * value = inputPoly[i];
        CGPoint point = [value pointValue];
        workingPoly.push_back(point);
        
    }
    
    VerticiesList workingOutputPolys;
    makeCCW(workingPoly);
    internalDecomposePoly(workingPoly,workingOutputPolys);
    
    NSMutableArray * decompyObjPolys = [NSMutableArray array];
    
    BOOL success = YES;
    
    for (int i =0; i < workingOutputPolys.size(); i++) {
        const Verticies &decompPoly = workingOutputPolys[i];
        
        NSMutableArray * decompObjPoly = [NSMutableArray array];
        [decompyObjPolys addObject:decompObjPoly];
        for(int j = 0; j < decompPoly.size(); j++)
        {
            CGPoint point = decompPoly[j];
            [decompObjPoly addObject:[NSValue valueWithPoint:point]];
        }
        if(decompObjPoly.count < 3)
            success = NO;
    }
    
    *outputPolys = decompyObjPolys;
    return success;
}

@end
    

////////////////////////////////////////////////////////////////////////////////
//Point operations.
#define PI 3.1415926535897932384626433832795

using namespace std;

typedef double Scalar;

bool eq(const Scalar &a, Scalar const &b);
Scalar min(const Scalar &a, const Scalar &b);
int wrap(const int &a, const int &b);
Scalar srand(const Scalar &min, const Scalar &max);

template<class T>
T& at(vector<T> v, int i) {
    return v[wrap(i, (int)v.size())];
};

CGPoint operator+(const CGPoint &a, const CGPoint &b);
Scalar area(const CGPoint &a, const CGPoint &b, const CGPoint &c);
bool left(const CGPoint &a, const CGPoint &b, const CGPoint &c);
bool leftOn(const CGPoint &a, const CGPoint &b, const CGPoint &c);
bool right(const CGPoint &a, const CGPoint &b, const CGPoint &c);
bool rightOn(const CGPoint &a, const CGPoint &b, const CGPoint &c);
bool collinear(const CGPoint &a, const CGPoint &b, const CGPoint &c);
Scalar sqdist(const CGPoint &a, const CGPoint &b);

////////////////////////////////////////////////////////////////////////////////

void makeCCW(Verticies & poly) {
    int br = 0;

    // find bottom right CGPoint
    for (int i = 1; i < poly.size(); ++i) {
        if (poly[i].y < poly[br].y || (poly[i].y == poly[br].y && poly[i].x > poly[br].x)) {
            br = i;
        }
    }

    // reverse poly if clockwise
    if (!left(at(poly, br - 1), at(poly, br), at(poly, br + 1))) {
        reverse(poly.begin(), poly.end());
    }
}

bool isReflex(const Verticies &poly, const int &i) {
    return right(at(poly, i - 1), at(poly, i), at(poly, i + 1));
}



CGPoint intersection(const CGPoint &p1, const CGPoint &p2, const CGPoint &q1, const CGPoint &q2) {
    CGPoint i;
    Scalar a1, b1, c1, a2, b2, c2, det;
    a1 = p2.y - p1.y;
    b1 = p1.x - p2.x;
    c1 = a1 * p1.x + b1 * p1.y;
    a2 = q2.y - q1.y;
    b2 = q1.x - q2.x;
    c2 = a2 * q1.x + b2 * q1.y;
    det = a1 * b2 - a2*b1;
    if (!eq(det, 0)) { // lines are not parallel
        i.x = (b2 * c1 - b1 * c2) / det;
        i.y = (a1 * c2 - a2 * c1) / det;
    }
    return i;
}

void swap(int &a, int &b) {
    int c;
    c = a;
    a = b;
    b = c;
}

void internalDecomposePoly(const Verticies &inputPoly, VerticiesList & outputPolys)
{
    CGPoint upperInt, lowerInt, p, closestVert;
    Scalar upperDist, lowerDist, d, closestDist;
    int upperIndex, lowerIndex, closestIndex;
    Verticies lowerPoly, upperPoly;

    for (int i = 0; i < inputPoly.size(); ++i) {
        if (isReflex(inputPoly, i)) {

            upperDist = lowerDist = numeric_limits<Scalar>::max();
            for (int j = 0; j < inputPoly.size(); ++j) {
                if (left(at(inputPoly, i - 1), at(inputPoly, i), at(inputPoly, j))
                        && rightOn(at(inputPoly, i - 1), at(inputPoly, i), at(inputPoly, j - 1))) { // if line intersects with an edge
                    p = intersection(at(inputPoly, i - 1), at(inputPoly, i), at(inputPoly, j), at(inputPoly, j - 1)); // find the CGPoint of intersection
                    if (right(at(inputPoly, i + 1), at(inputPoly, i), p)) { // make sure it's inside the poly
                        d = sqdist(inputPoly[i], p);
                        if (d < lowerDist) { // keep only the closest intersection
                            lowerDist = d;
                            lowerInt = p;
                            lowerIndex = j;
                        }
                    }
                }
                if (left(at(inputPoly, i + 1), at(inputPoly, i), at(inputPoly, j + 1))
                        && rightOn(at(inputPoly, i + 1), at(inputPoly, i), at(inputPoly, j))) {
                    p = intersection(at(inputPoly, i + 1), at(inputPoly, i), at(inputPoly, j), at(inputPoly, j + 1));
                    if (left(at(inputPoly, i - 1), at(inputPoly, i), p)) {
                        d = sqdist(inputPoly[i], p);
                        if (d < upperDist) {
                            upperDist = d;
                            upperInt = p;
                            upperIndex = j;
                        }
                    }
                }
            }

            // if there are no vertices to connect to, choose a CGPoint in the middle
            if (lowerIndex == (upperIndex + 1) % inputPoly.size()) {

                p.x = (lowerInt.x + upperInt.x) / 2;
                p.y = (lowerInt.y + upperInt.y) / 2;

                if (i < upperIndex) {
                    lowerPoly.insert(lowerPoly.end(), inputPoly.begin() + i, inputPoly.begin() + upperIndex + 1);
                    lowerPoly.push_back(p);
                    upperPoly.push_back(p);
                    if (lowerIndex != 0) upperPoly.insert(upperPoly.end(), inputPoly.begin() + lowerIndex, inputPoly.end());
                    upperPoly.insert(upperPoly.end(), inputPoly.begin(), inputPoly.begin() + i + 1);
                } else {
                    if (i != 0) lowerPoly.insert(lowerPoly.end(), inputPoly.begin() + i, inputPoly.end());
                    lowerPoly.insert(lowerPoly.end(), inputPoly.begin(), inputPoly.begin() + upperIndex + 1);
                    lowerPoly.push_back(p);
                    upperPoly.push_back(p);
                    upperPoly.insert(upperPoly.end(), inputPoly.begin() + lowerIndex, inputPoly.begin() + i + 1);
                }
            } else {
                // connect to the closest CGPoint within the triangle

                if (lowerIndex > upperIndex) {
                    upperIndex += inputPoly.size();
                }
                closestDist = numeric_limits<Scalar>::max();
                for (int j = lowerIndex; j <= upperIndex; ++j) {
                    if (leftOn(at(inputPoly, i - 1), at(inputPoly, i), at(inputPoly, j))
                            && rightOn(at(inputPoly, i + 1), at(inputPoly, i), at(inputPoly, j))) {
                        d = sqdist(at(inputPoly, i), at(inputPoly, j));
                        if (d < closestDist) {
                            closestDist = d;
                            closestVert = at(inputPoly, j);
                            closestIndex = j % inputPoly.size();
                        }
                    }
                }

                if (i < closestIndex) {
                    lowerPoly.insert(lowerPoly.end(), inputPoly.begin() + i, inputPoly.begin() + closestIndex + 1);
                    if (closestIndex != 0) upperPoly.insert(upperPoly.end(), inputPoly.begin() + closestIndex, inputPoly.end());
                    upperPoly.insert(upperPoly.end(), inputPoly.begin(), inputPoly.begin() + i + 1);
                } else {
                    if (i != 0) lowerPoly.insert(lowerPoly.end(), inputPoly.begin() + i, inputPoly.end());
                    lowerPoly.insert(lowerPoly.end(), inputPoly.begin(), inputPoly.begin() + closestIndex + 1);
                    upperPoly.insert(upperPoly.end(), inputPoly.begin() + closestIndex, inputPoly.begin() + i + 1);
                }
            }

            // solve smallest poly first
            if (lowerPoly.size() < upperPoly.size()) {
                internalDecomposePoly(lowerPoly, outputPolys);
                internalDecomposePoly(upperPoly, outputPolys);
            } else {
                internalDecomposePoly(upperPoly, outputPolys);
                internalDecomposePoly(lowerPoly, outputPolys);
            }
            return;
        }
    }
    outputPolys.push_back(inputPoly);
}



Scalar min(const Scalar &a, const Scalar &b) {
    return a < b ? a : b;
}

bool eq(const Scalar &a, const Scalar &b) {
    return fabs(a - b) <= 1e-8;
}

int wrap(const int &a, const int &b) {
    return a < 0 ? a % b + b : a % b;
}

Scalar srand(const Scalar &min = 0, const Scalar &max = 1) {
    return rand() / (Scalar) RAND_MAX * (max - min) + min;
}


Scalar area(const CGPoint &a, const CGPoint &b, const CGPoint &c) {
    return (((b.x - a.x)*(c.y - a.y))-((c.x - a.x)*(b.y - a.y)));
}

bool left(const CGPoint &a, const CGPoint &b, const CGPoint &c) {
    return area(a, b, c) > 0;
}

bool leftOn(const CGPoint &a, const CGPoint &b, const CGPoint &c) {
    return area(a, b, c) >= 0;
}

bool right(const CGPoint &a, const CGPoint &b, const CGPoint &c) {
    return area(a, b, c) < 0;
}

bool rightOn(const CGPoint &a, const CGPoint &b, const CGPoint &c) {
    return area(a, b, c) <= 0;
}

bool collinear(const CGPoint &a, const CGPoint &b, const CGPoint &c) {
    return area(a, b, c) == 0;
}

Scalar sqdist(const CGPoint &a, const CGPoint &b) {
    Scalar dx = b.x - a.x;
    Scalar dy = b.y - a.y;
    return dx * dx + dy * dy;
}
