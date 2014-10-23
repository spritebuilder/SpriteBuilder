//
//  SBUpdater.h
//  SpriteBuilder
//
//  Created by John Twigg on 8/4/14.
//
//


@interface SBVersionComparitor : NSObject

- (NSComparisonResult)compareVersion:(NSString *)versionA toVersion:(NSString *)versionB;

@end

@interface SBUpdater : NSObject

@end
