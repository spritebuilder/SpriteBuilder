//
//  PlugInNodeViewHandler.h
//  CocosBuilder
//
//  Created by Viktor on 7/26/13.
//
//

#import <Foundation/Foundation.h>

@interface PlugInNodeViewHandler : NSObject
{
    NSCollectionView* collectionView;
}

- (id) initWithCollectionView:(NSCollectionView*)cv;

@end
