//
//  SBUpdater.m
//  SpriteBuilder
//
//  Created by John Twigg on 8/4/14.
//
//

#import "SBUpdater.h"
#import "SemanticVersioning.h"
//#define SB_SANDBOXED 1

@implementation SBUpdater



@end


@implementation SBVersionComparitor


- (NSComparisonResult)compareVersion:(NSString *)versionA toVersion:(NSString *)versionB; // *** MAY BE CALLED ON NON-MAIN THREAD!
{
	SemanticVersioning * semanticVersionA = [[SemanticVersioning alloc] initWithString:versionA];
	SemanticVersioning * semanticVersionB = [[SemanticVersioning alloc] initWithString:versionB];
	
	return [semanticVersionA compare:semanticVersionB];
}

@end