/*
 * CocosBuilder: http://www.cocosbuilder.com
 *
 * Copyright (c) 2011 Viktor Lidholt
 * Copyright (c) 2012 Zynga Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "CCBUtil.h"
#import "CGPointExtension.h"


CGPoint ccpRound(CGPoint pt)
{
    CGPoint rounded;
    rounded.x = roundf(pt.x);
    rounded.y = roundf(pt.y);
    return rounded;
}

// Return closest point on line segment vw and point p
CGPoint ccpClosestPointOnLine(CGPoint v, CGPoint w, CGPoint p)
{
    const float l2 =  ccpLengthSQ(ccpSub(w, v));  // i.e. |w-v|^2 -  avoid a sqrt
    if (l2 == 0.0)
        return v;   // v == w case

    // Consider the line extending the segment, parameterized as v + t (w - v).
    // We find projection of point p onto the line.
    // It falls where t = [(p-v) . (w-v)] / |w-v|^2
    const float t = ccpDot(ccpSub(p, v),ccpSub(w , v)) / l2;
    if (t < 0.0)
        return v;        // Beyond the 'v' end of the segment
    else if (t > 1.0)
        return w;  // Beyond the 'w' end of the segment
    
    const CGPoint projection =  ccpAdd(v,  ccpMult(ccpSub(w, v),t));  // v + t * (w - v);  Projection falls on the segment
    return projection;
}


@implementation CCBUtil


+ (void) setSelectedSubmenuItemForMenu:(NSMenu*)menu tag:(int)tag
{
    NSArray* items = [menu itemArray];
    for (int i = 0; i < [items count]; i++)
    {
        [(NSCell*)[items objectAtIndex:i] setState:NSOffState];
    }
    [[menu itemWithTag:tag] setState:NSOnState];
}

+ (NSArray*) findFilesOfType:(NSString*)type inDirectory:(NSString*)d
{
    NSMutableArray* result = [NSMutableArray array];
    
    NSArray* dir = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:d error:NULL];
    for (int i = 0; i < [dir count]; i++)
    {
        NSString* f = [dir objectAtIndex:i];
        
        if ([[f stringByDeletingPathExtension] hasSuffix:@"-hd"])
        {
            continue;
        }
        
        if ([[[f pathExtension] lowercaseString] isEqualToString:type])
        {
            [result addObject:f];
        }
    }
    
    return result;
}



@end
