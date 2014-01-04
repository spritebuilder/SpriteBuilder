//
//  UsageManager.m
//  SpriteBuilder
//
//  Created by Viktor on 12/2/13.
//
//

#import "UsageManager.h"
#import "HashValue.h"

@implementation UsageManager

- (void) registerUsage
{
    NSString* userID = [[NSUserDefaults standardUserDefaults] valueForKey:@"sbUserID"];
    if (userID)
    {
        NSString* urlStr = [NSString stringWithFormat:@"http://app.spritebuilder.com/spritebuilder/track?event=launch&id=%@", userID];
        NSURL* url = [NSURL URLWithString:urlStr];
        
        // Create the request.
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        
        // Create url connection and fire request
		NSURLConnection* connection = [[NSURLConnection alloc] initWithRequest:request delegate:NULL];
        [connection autorelease];
    }
    else
    {
        // Generate a new user ID
        userID = [[HashValue md5HashWithString:[NSString stringWithFormat:@"%d", rand()]] description];
        [[NSUserDefaults standardUserDefaults] setValue:userID forKey:@"sbUserID"];
        
        // Open welcome screen in browser
        //NSString* urlStr = [NSString stringWithFormat:@"http://app.spritebuilder.com/spritebuilder/welcome/%@", userID];
        //NSURL* url = [NSURL URLWithString:urlStr];
        
        //[[NSWorkspace sharedWorkspace] openURL:url];
    }
}

@end
