//
//  SBUpdater.m
//  SpriteBuilder
//
//  Created by John Twigg on 8/4/14.
//
//

#import "SBUpdater.h"
//#define SB_SANDBOXED 1

@implementation SBUpdater


-(instancetype)init{
	
#if SB_SANDBOXED
	return nil;
#else
	return [super init];
#endif

}

@end
