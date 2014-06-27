//
//  AndroidPluginInstaller.h
//  SpriteBuilder
//
//  Created by John Twigg on 6/27/14.
//
//

#import <Foundation/Foundation.h>

extern NSString*   kSBDefualtsIdentifier;

@interface AndroidPluginInstaller : NSObject

+(BOOL)installPlugin:(NSString**)output;
+(BOOL)verifyPluginInstallation:(NSString**)output;
+(BOOL)removePlugin:(NSString**)output;

+(BOOL)needsInstallation;
+(void)setInstallationVersion;
@end
