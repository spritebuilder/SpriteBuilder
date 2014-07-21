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



@interface LicenceManager : NSObject <NSURLConnectionDataDelegate>

+(BOOL)requiresLicensing;
+(void)test;
@end
