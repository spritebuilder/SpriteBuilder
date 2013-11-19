//
//  WarningOutlineHandler.h
//  SpriteBuilder
//
//  Created by John Twigg on 2013-11-13.
//
//

#import <Foundation/Foundation.h>

@class CCBWarnings;

@interface WarningOutlineHandler : NSObject <NSOutlineViewDelegate, NSOutlineViewDataSource>
{
    CCBWarnings * ccbWarnings;
}

-(void)updateWithWarnings:(CCBWarnings*)_ccbWarnings;

@end
