//
//  WarningOutlineHandler.h
//  SpriteBuilder
//
//  Created by John Twigg on 2013-11-13.
//
//

#import <Foundation/Foundation.h>

@class CCBWarnings;

@interface WarningTableViewHandler : NSObject <NSTableViewDelegate, NSTableViewDataSource>
{
    CCBWarnings *warnings;
}

-(void)updateWithWarnings:(CCBWarnings*)someWarnings;

@end
