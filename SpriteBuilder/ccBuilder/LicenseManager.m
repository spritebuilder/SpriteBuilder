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

static NSString * kLicenseUserSettingsKey = @"licenseUserSettings";
static NSString * kAuthorizationURL = @"";
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

-(void)completeValidateUserId:(NSDictionary*)validationInfo
{
	NSTimeInterval days = [validationInfo[@"license_expires_at"] doubleValue];
	NSDate * futureDate = [NSDate dateWithTimeIntervalSince1970:days];
	
	
	NSDictionary * licenseDetails = @{@"expireDate":@([futureDate timeIntervalSince1970])};
	
	[LicenseManager setLicenseDetails:licenseDetails];
}



-(void)validateUserId:(SuccessCallback)_successCallback error:(ErrorCallback)_errorCallback
{
	successCallback = [_successCallback copy];
	errorCallback   = [_errorCallback copy];
	
	ProjectSettings* projectSettings = [[ProjectSettings alloc] init];
	NSMutableDictionary * mutableData = [NSMutableDictionary dictionary];
	[mutableData addEntriesFromDictionary:[projectSettings getVersionDictionary]];
	
		
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:kAuthorizationURL]];
//    NSURLConnection *urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	
	NSOperationQueue *queue = [[NSOperationQueue alloc] init];
	[NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *licenseData, NSError *error) {
		
		{ //Test code!
			NSDictionary * testDict = @{@"license_expires_at" : @([[NSDate dateWithTimeIntervalSinceNow:60.0 * 60.0 * 24.0 * 5.0f] timeIntervalSince1970])};
			[self completeValidateUserId:testDict];
			successCallback(testDict);
			return;
		}
		
		if ([licenseData length] > 0 && error == nil)
		{
			NSError *jsonParsingError = nil;
			
			NSDictionary * resultDict = [NSJSONSerialization JSONObjectWithData:licenseData options:0 error:&jsonParsingError];
			
			if (jsonParsingError) {
				errorCallback([jsonParsingError localizedDescription]);
				return;
			}
			
			if(resultDict[@"error"])
			{
				errorCallback(resultDict[@"message"]);
				return;
			}
			
			[self completeValidateUserId:(NSDictionary*)resultDict];
			successCallback(resultDict);
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
			errorCallback(error.localizedDescription);
		}
	}];
}



												 
												 
@end
