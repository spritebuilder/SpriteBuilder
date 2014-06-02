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

@implementation UsageManager

- (void) registerUsage
{
    _userID = [[NSUserDefaults standardUserDefaults] valueForKey:@"sbUserID"];
    
    BOOL firstTimeUser = NO;
    
    if (!_userID)
    {
        // Create and save new unique id
        _userID = [[HashValue md5HashWithString:[NSString stringWithFormat:@"%d", (int)arc4random()]] description];
        [[NSUserDefaults standardUserDefaults] setValue:_userID forKey:@"sbUserID"];
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

- (void) registerEmail:(NSString*)email
{
    // Get user ID
    _userID = [[NSUserDefaults standardUserDefaults] valueForKey:@"sbUserID"];
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
