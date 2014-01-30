//
//  PlugInNodeViewHandler.h
//  CocosBuilder
//
//  Created by Viktor on 7/26/13.
//
//

#import <Foundation/Foundation.h>
#import "ProjectSettings.h"

@interface PlugInNodeViewHandler : NSObject <NSCollectionViewDelegate>
{
    NSCollectionView* collectionView;
    NSMutableArray* plugIns;
}

- (id) initWithCollectionView:(NSCollectionView*)cv;

-(void) showNodePluginsForEngine:(CCBTargetEngine)engine;

@end
