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
#import "LicenseManager.h"

NSString * kSbUserID = @"sbUserID";
NSString * kSbRegisteredEmail = @"sbRegisteredEmail";

@interface NSDictionary (UrlEncoding)
-(NSString*) urlEncodedString;
@end


// helper function: get the string form of any object
static NSString *toString(id object) {
	return [NSString stringWithFormat: @"%@", object];
}

// helper function: get the url encoded string form of any object
static NSString *urlEncode(id object) {
	NSString *string = toString(object);
	return [string stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
}

@implementation NSDictionary (UrlEncoding)

-(NSString*) urlEncodedString {
	NSMutableArray *parts = [NSMutableArray array];
	for (id key in self) {
		id value = [self objectForKey: key];
		NSString *part = [NSString stringWithFormat: @"%@=%@", urlEncode(key), urlEncode(value)];
		[parts addObject: part];
	}
	return [parts componentsJoinedByString: @"&"];
}

@end

@implementation UsageManager
@dynamic userID;

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

- (void) registerEmail:(NSString*)email reveiveNewsLetter:(BOOL)receiveNewsLetter
{
    // Get user ID
    if (!_userID)
		return;
    
    [self sendEvent:@"register" data:@{@"email":email, @"receive_newsletter": @(receiveNewsLetter)}];
}

- (void) sendEvent:(NSString*)evt
{
    [self sendEvent:evt data:nil];
}

-(NSString*)userID
{
	return _userID;
}

-(NSDictionary*)usageDetails
{
	NSMutableDictionary * mutableData = [NSMutableDictionary dictionary];
		
	ProjectSettings* projectSettings = [[ProjectSettings alloc] init];
	
    // Version.txt information
	[mutableData addEntriesFromDictionary:[projectSettings getVersionDictionary]];
	
/// License manager.
	[mutableData addEntriesFromDictionary:[LicenseManager getLicenseDetails]];
	
	
	NSString * serialNumber = [self serialNumber];
	if(!serialNumber)
		serialNumber = @"";
	mutableData[@"serial_number"] = serialNumber;
	
    // URL encode email
	
	mutableData[@"id"] = _userID;

	return mutableData;
}

- (void) sendEvent:(NSString*)evt data:(NSDictionary*)data;
{
	NSMutableDictionary * mutableData = [NSMutableDictionary dictionaryWithDictionary:[self usageDetails]];
	[mutableData addEntriesFromDictionary:data];
	
	NSString * params = [mutableData urlEncodedString];
	
    
    // Create URL
    NSString* urlStr = [NSString stringWithFormat:@"http://app.spritebuilder.com/spritebuilder/track?event=%@&%@", evt,params];
	
	
    NSURL* url = [NSURL URLWithString:urlStr];
    
    // Create the request
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
	NSLog(@"Sending event: %@", urlStr);
    // Create url connection and fire request
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:NULL];
	connection = nil; // make the compiler violently happy
}

- (NSString *)serialNumber
{
    io_service_t    platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault,
																 
																 IOServiceMatching("IOPlatformExpertDevice"));
    CFStringRef serialNumberAsCFString = NULL;
	
    if (platformExpert) {
        serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert,
																 CFSTR(kIOPlatformSerialNumberKey),
																 kCFAllocatorDefault, 0);
        IOObjectRelease(platformExpert);
    }
	
    NSString *serialNumberAsNSString = nil;
    if (serialNumberAsCFString) {
        serialNumberAsNSString = [NSString stringWithString:(__bridge NSString *)serialNumberAsCFString];
        CFRelease(serialNumberAsCFString);
    }
	
    return serialNumberAsNSString;
}

@end
