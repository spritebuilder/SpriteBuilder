//
//  LicenceManager.h
//  SpriteBuilder
//
//  Created by John Twigg on 7/18/14.
//
//

#import <Foundation/Foundation.h>

typedef void (^SuccessCallback) (NSDictionary * licenseInfo);
typedef void (^ErrorCallback) (NSString * errorMessage);

NSString * kLicenseDetailsUpdated;

@interface LicenseManager : NSObject

+(BOOL)requiresLicensing;

-(void)validateUserId:(SuccessCallback)_successCallback error:(ErrorCallback)_errorCallback;

+(NSDictionary*)getLicenseDetails;
@end
