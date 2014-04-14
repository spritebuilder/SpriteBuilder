//
//  NSArray+Query.h
//  SpriteBuilder
//
//  Created by John Twigg on 2/6/14.
//
//

#import <Foundation/Foundation.h>

typedef id (^ConvertBlock) (id obj, int idx);//Convert obj into a different type.
typedef BOOL (^PredicateBlock) (id obj, int idx);//Return true if obj conforms to predicate.
typedef void (^ActionBlock) (id obj, int idx); //Perform an action on obj.


@interface NSArray (Query)

//Converts all objects in an to a a different type.
-(NSArray*)convertAll:(ConvertBlock)aBlock;

//Find first item in the list that conforms to the predicate.
-(id)findFirst:(PredicateBlock)aBlock;

//Find the last item in the list that conforms to the predicate.
-(id)findLast:(PredicateBlock)aBlock;

//Return a sublist of items that conform to a predicate.
-(NSArray*)where:(PredicateBlock)aBlock;

//perform an operation on each item in the list.
-(void)forEach:(ActionBlock)aBlock;
@end
