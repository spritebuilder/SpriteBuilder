//
//  PreferenceOptiPNGViewController.m
//  PreferenceWindow
//
//  Created by Nicky Weber on 18.03.14.
//  Copyright (c) 2014 Nicky Weber. All rights reserved.
//

#import "PreferenceOptiPNGViewController.h"
#import "SBUserDefaultsKeys.h"

@interface PreferenceOptiPNGViewController ()

@end

@implementation PreferenceOptiPNGViewController

- (id)init
{
	self = [super initWithNibName:@"PreferenceOptiPNG" bundle:nil];
	if (self)
	{

	}
	return self;
}

- (IBAction)chooseOptiPNGInstallationPath:(id)sender
{
	NSOpenPanel *openPanel = [[NSOpenPanel alloc] init];
	openPanel.canChooseDirectories = NO;
	openPanel.showsHiddenFiles = YES;
	openPanel.allowsMultipleSelection = NO;
	openPanel.directoryURL = [NSURL URLWithString:[self.optiPNGPathTextField.stringValue stringByDeletingLastPathComponent]];

	[openPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result)
	{
		if (result == NSOKButton && [[openPanel URLs] count] == 1)
		{
			[[NSUserDefaults standardUserDefaults] setValue:[[openPanel URLs][0] path] forKey:PREFERENCES_OPTIPNG_INSTALLATION_PATH];
		}
	}];
}

- (IBAction)testOptiPNG:(id)sender
{
	NSString *path = self.optiPNGPathTextField.stringValue;

	NSFileManager *fileManager = [NSFileManager defaultManager];
	if (![fileManager fileExistsAtPath:path])
	{
		NSAlert *alert = [NSAlert alertWithError:[NSError errorWithDomain:@"" code:1 userInfo:@{NSLocalizedDescriptionKey:@"File does not exist."}]];
		[alert beginSheetModalForWindow:self.view.window modalDelegate:nil didEndSelector:nil contextInfo:nil];
	}
	else
	{
		[self runTestWithPath:path];
	}
}

- (void)runTestWithPath:(NSString *)path
{
	NSTask *task = [[NSTask alloc] init];
	[task setLaunchPath:path];
	[task setArguments:@[@"--version"]];

	NSPipe *pipe = [NSPipe pipe];
	[task setStandardOutput:pipe];

	NSFileHandle *file = [pipe fileHandleForReading];

	[task launch];

	NSData *data = [file readDataToEndOfFile];

	NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

	NSAlert *alert = [NSAlert alertWithMessageText:path
									 defaultButton:@"OK"
								   alternateButton:nil
									   otherButton:nil
						 informativeTextWithFormat:@"%@", string];

	[alert beginSheetModalForWindow:self.view.window modalDelegate:nil didEndSelector:nil contextInfo:nil];
}


@end
