//
//  NSArray+Query.m
//  SpriteBuilder
//
//  Created by John Twigg on 2/6/14.
//
//

#import "NSArray+Query.h"

@implementation NSArray (Query)

-(NSArray*)convertAll:(ConvertBlock)aBlock
{
    NSMutableArray * returnArray = [NSMutableArray array];
    
    for (int i = 0; i < self.count; i++) {
        id returnObj = aBlock(self[i], i);
        [returnArray addObject	:returnObj];
    }
    
    return returnArray;
}

-(id)findFirst:(PredicateBlock)aBlock
{
    for (int i = 0; i < self.count; i++) {
        if(aBlock(self[i], i))
        {
            return self[i];
        }
    }
    return nil;
}

-(void)forEach:(VoidBlock)aBlock
{
    for (int i = 0; i < self.count; i++) {
        aBlock(self[i], i);
    }
    
}

@end
