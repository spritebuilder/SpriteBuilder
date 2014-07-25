//
//  LicenceManager.m
//  SpriteBuilder
//
//  Created by John Twigg on 7/18/14.
//
//

#import "LicenceManager.h"
#import "CocoaSecurity.h"

//NSString * kPrivateKey = @"M9LDDVAKHiEueQLcaGkPq+SOBJPllzwhGTkLPsaDrjM=";

static NSString * kLicenseUserSettingsKey = @"licenseUserSettings";
static NSString * kSBProPrivateKey = @"SBProPrivateKey";
@implementation LicenceManager
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


+(NSDictionary*)licenseUserSettings
{
	return [[NSUserDefaults standardUserDefaults] dictionaryForKey:kLicenseUserSettingsKey];
}
												 

+(NSDictionary*)getLicenseDetails
{
 
	NSString * privateKey = [NSString stringWithUTF8String:SBPRO_PRIVATE_KEY];
	
	NSDictionary * licenseSettings = [self licenseUserSettings];
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

}



+(void)encodeTestData
{
	NSTimeInterval days5 = -5.0 * 60.0 * 60.0 * 24.0;
	NSDate * futureDate = [NSDate dateWithTimeIntervalSinceNow:days5];

	
	NSDictionary * licenseDetails = @{@"expireDate":@([futureDate timeIntervalSince1970])};
	
	[self setLicenseDetails:licenseDetails];
	
}

+(void)test
{
	[self encodeTestData];
	
	NSDictionary * licenseDetails = [self getLicenseDetails];
	
	BOOL result = [self requiresLicensing];
	

}



-(void)validateLicenseKey:(NSString*)registrationKey success:(SuccessCallback)_successCallback error:(ErrorCallback)_errorCallback
{
	successCallback = [_successCallback copy];
	errorCallback   = [_errorCallback copy];
		
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@""]];
//    NSURLConnection *urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	NSOperationQueue *queue = [[NSOperationQueue alloc] init];
	[NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *licenseData, NSError *error) {
		
		if ([licenseData length] > 0 && error == nil)
		{
			NSError *jsonParsingError = nil;
			
			id object = [NSJSONSerialization JSONObjectWithData:licenseData options:0 error:&jsonParsingError];
			
			if (jsonParsingError) {
				errorCallback([jsonParsingError localizedDescription]);
				return;
			}
			
			successCallback(object);
		}
		else if ([licenseData length] == 0 && error == nil)
		{
			errorCallback(@"Empy response from server");
		}
		else if (error != nil && error.code == NSURLErrorTimedOut)
		{
			errorCallback(@"Server Times out.");
		}
		else if (error != nil)
		{
			errorCallback(@"Download error.");
		}
		
	}];
}



												 
												 
@end
