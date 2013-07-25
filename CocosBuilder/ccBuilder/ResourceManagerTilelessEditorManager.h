//
//  ResourceManagerTilelessEditorManager.h
//  CocosBuilder
//
//  Created by Viktor on 7/24/13.
//
//

#import <Foundation/Foundation.h>
#import <Quartz/Quartz.h>

@class CCBImageBrowserView;

@interface ResourceManagerTilelessEditorManager : NSObject
{
    CCBImageBrowserView* browserView;
    NSMutableArray* imageResources;
    NSMutableArray* imageGroups;
}

- (id) initWithImageBrowser:(CCBImageBrowserView*)bw;

@end
