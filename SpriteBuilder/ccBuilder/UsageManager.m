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
		id value = self[key];
		NSString *part = [NSString stringWithFormat: @"%@=%@", urlEncode(key), urlEncode(value)];
		[parts addObject: part];
	}
	return [parts componentsJoinedByString: @"&"];
}

@end

@implementation UsageManager
@dynamic userID;

+ (UsageManager*)sharedManager {
    static UsageManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

-(id)init
{
	self = [super init];
	if(self)
	{
		 _userID = [[NSUserDefaults standardUserDefaults] valueForKey:kSbUserID];
	}
	
	return self;
}

-(void)setRegisterdEmailFlag
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:kSbRegisteredEmail];
}

- (void) registerUsage
{
    BOOL firstTimeUser = NO;
    
    if (!_userID)
    {
        // Create and save new unique id
        _userID = [[HashValue md5HashWithString:[NSString stringWithFormat:@"%d", (int)arc4random()]] description];
        [[NSUserDefaults standardUserDefaults] setValue:_userID forKey:kSbUserID];
        firstTimeUser = YES;
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

	NSString * serialNumber = [self serialNumber];
	if(!serialNumber)
		serialNumber = @"";
	mutableData[@"serial_number"] = serialNumber;
	mutableData[@"id"] = _userID;

	return mutableData;
}

- (void) sendEvent:(NSString*)evt data:(NSDictionary*)data;
{
    #if TESTING
    return;
    #endif

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
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:NULL ];
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
