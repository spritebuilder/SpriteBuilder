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

@interface ResourceManagerTilelessEditorManager : NSObject <NSTableViewDataSource, NSTableViewDelegate, NSSplitViewDelegate>
{
    CCBImageBrowserView* browserView;
    NSMutableArray* imageResources;
    NSMutableArray* imageGroups;
    NSMutableArray* imageGroupsActive;
}

- (id) initWithImageBrowser:(CCBImageBrowserView*)bw;

@end
