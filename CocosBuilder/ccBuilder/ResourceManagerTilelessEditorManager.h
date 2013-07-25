//
//  ResourceManagerTilelessEditorManager.h
//  CocosBuilder
//
//  Created by Viktor on 7/24/13.
//
//

#import <Foundation/Foundation.h>
#import <Quartz/Quartz.h>

@interface ResourceManagerTilelessEditorManager : NSObject
{
    IKImageBrowserView* browserView;
    NSMutableArray* imageResources;
}

- (id) initWithImageBrowser:(IKImageBrowserView*)bw;

@end
