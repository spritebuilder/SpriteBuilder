//
//  NSArray+Query.h
//  SpriteBuilder
//
//  Created by John Twigg on 2/6/14.
//
//

#import <Foundation/Foundation.h>

typedef id (^ConvertBlock) (id obj, int idx);

@interface NSArray (Query)


//Converts all objects in an to a a different type.
-(NSArray*)convertAll:(ConvertBlock)aBlock;

@end
