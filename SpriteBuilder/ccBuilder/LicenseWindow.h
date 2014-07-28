//
//  LicenseWindow.h
//  SpriteBuilder
//
//  Created by John Twigg on 7/18/14.
//
//

#import <Cocoa/Cocoa.h>

typedef enum
{
	eLicenseState_ConnectingToServer,
	eLicenseState_PollingServer,
	eLicenseState_VerififcationComplete,
}eLicenseState;



@interface LicenseWindow : NSWindowController

-(void)setState:(eLicenseState)state;

@end
