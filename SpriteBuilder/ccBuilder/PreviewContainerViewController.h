//
//  PreviewContainerViewController.h
//  SpriteBuilder
//
//  Created by Nicky Weber on 26.08.14.
//
//

#import <Cocoa/Cocoa.h>
#import "PreviewViewControllerProtocol.h"

@class RMResource;
@class ProjectSettings;

@interface PreviewContainerViewController : NSViewController <NSSplitViewDelegate, PreviewViewControllerProtocol>

@end
