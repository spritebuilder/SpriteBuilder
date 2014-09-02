//
//  LicenceManager.m
//  SpriteBuilder
//
//  Created by John Twigg on 7/18/14.
//
//

#import "LicenseManager.h"
#import "CocoaSecurity.h"
#import "ProjectSettings.h"
#import "UsageManager.h"

static NSString * kLicenseUserSettingsKey = @"licenseUserSettings";
static NSString * kAuthorizationURL = @"http://www.spritebuilder.com/api/v1/authorization";
NSString * kLicenseDetailsUpdated = @"kLicenseDetailsUpdated";

@interface NSDictionary (UrlEncoding)
-(NSString*) urlEncodedString ;
@end

@implementation LicenseManager
{
	SuccessCallback successCallback;
	ErrorCallback   errorCallback;
}

+(BOOL)requiresLicensing
{
	NSDictionary * licenseDetails = [self getLicenseDetails];
	if(licenseDetails == nil)
		return YES;
	
	if(licenseDetails)
	{
		NSTimeInterval expireDateInterval = [licenseDetails[@"expireDate"] doubleValue];
		
		NSDate * expireDate = [NSDate dateWithTimeIntervalSince1970:expireDateInterval];
		NSDate * todayDate = [NSDate date];
		
		if([todayDate compare:expireDate] == NSOrderedDescending)
		{
			return YES;
		}
		return NO;
	}
	
	return YES;

}


+(NSDictionary*)getLicenseDetails
{
 
	NSString * privateKey = [NSString stringWithUTF8String:SBPRO_PRIVATE_KEY];
	
	NSDictionary * licenseSettings = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kLicenseUserSettingsKey];
	if(licenseSettings == nil)
		return nil;
	
	NSString * registrationKey = licenseSettings[@"licenseKey"];
	
	CocoaSecurityResult * result = [CocoaSecurity aesDecryptWithBase64:registrationKey key:privateKey];

	NSError * error;
	
	NSDictionary * licenseDetails = [NSJSONSerialization
				 JSONObjectWithData:	result.data
				 options:0
				 error:&error];
	
	
	if(licenseDetails == nil)
	{
		NSLog(@"Error decoding license details");
	}
	
	return licenseDetails;
}

+(void)setLicenseDetails:(NSDictionary*)licenseDetails
{
	
	NSError * error;
	NSData * jsonData = [NSJSONSerialization dataWithJSONObject:licenseDetails options:NSJSONWritingPrettyPrinted error:&error];
	NSString * jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
	
	NSString * privateKey = [NSString stringWithUTF8String:SBPRO_PRIVATE_KEY];
	
	CocoaSecurityResult * result = [CocoaSecurity aesEncrypt:jsonString key:privateKey];
	NSLog(@"StringKey : %@", result.base64);
	
	[[NSUserDefaults standardUserDefaults] setObject:@{@"licenseKey" : result.base64} forKey:kLicenseUserSettingsKey];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kLicenseDetailsUpdated object:licenseDetails];

}


-(void)updateAuthorizeInfo:(NSDictionary*)authorizationResult
{
	NSTimeInterval days = [authorizationResult[@"license_expires_at"] doubleValue];
	NSDate * futureDate = [NSDate dateWithTimeIntervalSince1970:days];
	
	NSString * email = @"";
	if(authorizationResult[@"email"])
	{
		email = authorizationResult[@"email"];
	}

	
	NSDictionary * licenseDetails = @{@"expireDate":@([futureDate timeIntervalSince1970]), @"email" : email};

	[LicenseManager setLicenseDetails:licenseDetails];
}



-(void)validateUserId:(SuccessCallback)_successCallback error:(ErrorCallback)_errorCallback
{
	successCallback = [_successCallback copy];
	errorCallback   = [_errorCallback copy];
	
	UsageManager * usageManager = [[UsageManager alloc] init];
	

	NSDictionary * usagedetails = [usageManager usageDetails];

	
	NSString * params = [usagedetails urlEncodedString];
	// Create URL
    NSString* urlStr = [NSString stringWithFormat:@"%@?%@", kAuthorizationURL, params];
	
		
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]];
//    NSURLConnection *urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	
	
	NSOperationQueue *queue = [[NSOperationQueue alloc] init];
	[NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *licenseData, NSError *error) {
		

		
		if ([licenseData length] > 0 && error == nil)
		{
			NSError *jsonParsingError = nil;
			
			NSDictionary * authorizationResult = [NSJSONSerialization JSONObjectWithData:licenseData options:0 error:&jsonParsingError];
			
			if (jsonParsingError) {
				errorCallback([jsonParsingError localizedDescription]);
				return;
			}
			
			if(authorizationResult[@"error"])
			{
				errorCallback(authorizationResult[@"message"]);
				return;
			}
			
			[self updateAuthorizeInfo:(NSDictionary*)authorizationResult];
			
			
			if([LicenseManager requiresLicensing])
			{
				NSDictionary * licenseDetails = [LicenseManager getLicenseDetails];
				
				NSTimeInterval expireDateInterval = [licenseDetails[@"expireDate"] doubleValue];
				
				NSDate * expireDate = [NSDate dateWithTimeIntervalSince1970:expireDateInterval];
				NSDate * todayDate = [NSDate date];
				
				if([todayDate compare:expireDate] == NSOrderedDescending)
				{
					errorCallback(@"You're license has expired. Please login to renew it.");
				}
				else
				{
					errorCallback(@"You're license is invalid. Please login to refresh it.");
				}
				
				return;
			}
			
			//Sucess
			[usageManager sendEvent:@"register"];
			
			successCallback(authorizationResult);
		}
		else if ([licenseData length] == 0 && error == nil)
		{
			errorCallback(@"No response from the server");
		}
		else if (error != nil && error.code == NSURLErrorTimedOut)
		{
			errorCallback(@"Server timed out.");
		}
		else if (error != nil)
		{
			errorCallback(error.localizedDescription);
		}
	}];
}



												 
												 
@end
