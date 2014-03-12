//
//  CCScrollListView.m
//  CocosBuilder
//
//  Created by Mikhail Perekhodtsev on 8/6/13.
//
//

#import "cocos2d.h"
#import "CCScrollView.h"

@class ItemStruct;
@class IndexItem;

@interface CCBPScrollListView : CCScrollView
{
    NSMutableDictionary *_items;
    NSMutableDictionary *_selectorIndex;
    NSEnumerator *_curitem;
    
    BOOL _horizontal;
    CCTextAlignment _textAlignment;
    CCVerticalTextAlignment _verticalTextAlignment;
}

-(void)RecalcPositions;
-(CCNode *)AddElement:(NSString *)name;
-(CCNode *)nodeFromTemplate;

@property (nonatomic, retain) NSString *_template;
@property (nonatomic, assign) BOOL horizontal;
@property (nonatomic, assign) NSInteger _count;
@property (nonatomic, assign) CCTextAlignment textAlignment;
@property (nonatomic, assign) CCVerticalTextAlignment verticalTextAlignment;

@end