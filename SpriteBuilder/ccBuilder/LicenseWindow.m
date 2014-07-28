//
//  LicenseWindow.m
//  SpriteBuilder
//
//  Created by John Twigg on 7/18/14.
//
//

#import "LicenseWindow.h"
#import "LicenseManager.h"

@interface LicenseWindow ()
{
	eLicenseState _state;
	LicenseManager *licenseManager;
	ErrorCallback errorCallback;
}

@property (weak) IBOutlet NSButton *continueButton;
@property (weak) IBOutlet NSProgressIndicator *busyIndicator;
@property (weak) IBOutlet NSButton *connectToServerButton;
@property (weak) IBOutlet NSTextField *displayText;
@property (weak) IBOutlet NSTextField *expiryDate;

@end

@implementation LicenseWindow

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
		licenseManager = [[LicenseManager alloc] init];
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
	
	[self setState:eLicenseState_ConnectingToServer];
	
	licenseManager = [[LicenseManager alloc] init];
	
	 __weak LicenseWindow * weakSelf = self;
	
	errorCallback = ^(NSString *errorMessage) {
		[weakSelf.busyIndicator stopAnimation:weakSelf];
		[weakSelf.busyIndicator setHidden:YES];
		[weakSelf displayError:errorMessage];
		[weakSelf setState:eLicenseState_PollingServer];
		
		
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
			[weakSelf sendPoll];
		});
		
		
		
	};
	
	self.expiryDate.stringValue = @"";
	[self.busyIndicator startAnimation:self];
	[self sendPoll];
	
}

-(void)sendPoll
{
	__weak LicenseWindow * weakSelf = self;
	
	[licenseManager validateUserId:^(NSDictionary *licenseInfo) {
		[weakSelf.busyIndicator stopAnimation:self];
		[weakSelf.busyIndicator setHidden:YES];

		
		NSDictionary * licenseDetails = [LicenseManager getLicenseDetails];
		NSTimeInterval expireDateTime = [licenseDetails[@"expireDate"] doubleValue];
		NSDate * expireDate = [NSDate dateWithTimeIntervalSince1970: expireDateTime];
		NSString  * formattedDate = [NSDateFormatter localizedStringFromDate:expireDate dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterNoStyle];
		
		weakSelf.displayText.stringValue = @"SpriteBuilder Pro was successfully licensed!";
		weakSelf.expiryDate.stringValue = formattedDate;
		
		[self setState:eLicenseState_VerififcationComplete];
	} error:errorCallback];

}

- (IBAction)onHandleLoginToSBSite:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://forum.spritebuilder.com"]];
}

- (IBAction)onHandleContinue:(id)sender {
	
	[NSApp stopModal];
	

}
- (IBAction)onHandleQuit:(id)sender {
	
	[NSApp abortModal];
}

-(void)displayError:(NSString*)errorMessage
{
	self.displayText.stringValue = errorMessage;
}


-(void)setState:(eLicenseState)state
{
	_state = state;
	
	switch (_state) {
		case eLicenseState_ConnectingToServer:
			
			[self.continueButton setEnabled:NO];
			[self.connectToServerButton setEnabled:NO];
			break;
		case eLicenseState_VerififcationComplete:
			[self.continueButton setEnabled:YES];
			break;
		case eLicenseState_PollingServer:
			[self.continueButton setEnabled:NO];
			[self.connectToServerButton setEnabled:YES];
		default:
			break;
	}
}

@end
