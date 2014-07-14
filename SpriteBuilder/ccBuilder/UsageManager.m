//
//  UsageManager.m
//  SpriteBuilder
//
//  Created by Viktor on 12/2/13.
//
//

#import "UsageManager.h"
#import "HashValue.h"
#import "ProjectSettings.h"

NSString * kSbUserID = @"sbUserID";
NSString * kSbRegisteredEmail = @"sbRegisteredEmail";

@implementation UsageManager

-(id)init
{
	self = [super init];
	if(self)
	{
		 _userID = [[NSUserDefaults standardUserDefaults] valueForKey:kSbUserID];
	}
	
	return self;
}

#ifdef SPRITEBUILDER_PRO

-(void)migrateSandboxToPro
{
    //Its already all setup.
    if (_userID)
		return;

	//Check for previous SpriteBuilder (Sandboxed) information.
	//Sandboxed path
	NSString * preferencesPath = [self sandboxPreferencesPath];
	

	NSFileManager * fileManager  = [[NSFileManager alloc] init];

	if([fileManager fileExistsAtPath:preferencesPath])
	{
		NSDictionary * sandBoxedPrefs = [NSDictionary dictionaryWithContentsOfFile:preferencesPath];
		if(sandBoxedPrefs[kSbUserID])
		{
			
			_userID = sandBoxedPrefs[kSbUserID];
			[[NSUserDefaults standardUserDefaults] setValue:_userID forKey:kSbUserID];
			
			if(sandBoxedPrefs[kSbRegisteredEmail])
			{
				[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:kSbRegisteredEmail];
			}
			[self sendEvent:@"migrate"];
		}
	}
}


-  (NSString *) sandboxPreferencesPath
{
	NSArray *domains = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,NSUserDomainMask,YES);
	NSString *baseDir= [domains objectAtIndex:0];
	NSString *result = [baseDir stringByAppendingPathComponent:@"/Containers/SpriteBuilder/Data/Library/Preferences/SpriteBuilder.plist"];
	return result;
}

//This ensures that if we've opened SB Pro for the first time, AND the user's never opened SB Default before, a pref's file is created for when SB default is launched.
//https://developer.apple.com/library/mac/documentation/Security/Conceptual/AppSandboxDesignGuide/MigratingALegacyApp/MigratingAnAppToASandbox.html#//apple_ref/doc/uid/TP40011183-CH6-SW1

-(void)ensureSandboxConsistancy
{
	
	NSArray *domains = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,NSUserDomainMask,YES);
	NSString *baseDir= [domains objectAtIndex:0];
	NSString * sandboxMigrationPath = [baseDir stringByAppendingPathComponent:@"/Preferences/SpriteBuilder.plist"];

	NSMutableDictionary * userSettingsDictionary = [NSMutableDictionary dictionary];
	
	userSettingsDictionary[kSbUserID] = _userID;
	BOOL registeredEmail = [[NSUserDefaults standardUserDefaults] objectForKey:kSbRegisteredEmail] != nil;
	
	if(registeredEmail)
	{
		userSettingsDictionary[kSbRegisteredEmail] = @(registeredEmail);
	}
	
	if(![userSettingsDictionary writeToFile:sandboxMigrationPath atomically:YES])
	{
		NSLog(@"Failed to write to: %@",sandboxMigrationPath);
	}
	
}

#endif

-(void)setRegisterdEmailFlag
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:kSbRegisteredEmail];
		
#ifdef SPRITEBUILDER_PRO
	[self ensureSandboxConsistancy];
#endif
}


- (void) registerUsage
{
#ifdef SPRITEBUILDER_PRO
	[self migrateSandboxToPro];
#endif
   
    
    BOOL firstTimeUser = NO;
    
    if (!_userID)
    {
        // Create and save new unique id
        _userID = [[HashValue md5HashWithString:[NSString stringWithFormat:@"%d", (int)arc4random()]] description];
        [[NSUserDefaults standardUserDefaults] setValue:_userID forKey:kSbUserID];
        firstTimeUser = YES;
		
#ifdef SPRITEBUILDER_PRO
		[self ensureSandboxConsistancy];
#endif
		
    }
    
    if (firstTimeUser)
    {
        [self sendEvent:@"install"];
    }
    else
    {
        [self sendEvent:@"launch"];
    }
}

- (void) registerEmail:(NSString*)email
{
    // Get user ID
    if (!_userID) return;
    
    [self sendEvent:@"register" email:email];
}

- (void) sendEvent:(NSString*)evt
{
    [self sendEvent:evt email:@""];
}

- (void) sendEvent:(NSString*)evt email:(NSString*)email
{
    ProjectSettings* projectSettings = [[ProjectSettings alloc] init];
    
    // Version
    NSString* version = [projectSettings getVersion];
    if (version)
    {
        // URL encode version
        version = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)version, NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]\n", kCFStringEncodingUTF8));
    }
    else
    {
        version = @"";
    }
    
    // URL encode email
    email = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)email, NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]\n", kCFStringEncodingUTF8));
    
    // Create URL
    NSString* urlStr = [NSString stringWithFormat:@"http://app.spritebuilder.com/spritebuilder/track?event=%@&id=%@&version=%@&email=%@", evt, _userID, version,email];
    NSURL* url = [NSURL URLWithString:urlStr];
    
    // Create the request
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    // Create url connection and fire request
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:NULL];
	connection = nil; // make the compiler violently happy
}

@end
