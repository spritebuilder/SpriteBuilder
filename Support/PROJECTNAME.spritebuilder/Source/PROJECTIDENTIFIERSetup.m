//
//  PROJECTIDENTIFIERSetup.m
//  PROJECTNAME
//


#import "PROJECTIDENTIFIERSetup.h"


@implementation PROJECTIDENTIFIERSetup

-(NSDictionary *)baseConfig
{
    return [super baseConfig];
}

- (void)setupApplication
{
    [super setupApplication];
}

- (NSString *)firstSceneName
{
    return @"MainScene";
}

//MARK: iOS
#if __CC_PLATFORM_IOS

-(void)setupIOS
{
    [CCFileLocator sharedFileLocator].searchPaths = [@[
        [[NSBundle mainBundle] pathForResource:@"Published-iOS" ofType:nil],
    ] arrayByAddingObjectsFromArray:[CCFileLocator sharedFileLocator].searchPaths];
    
    [super setupIOS];
}

#endif

//MARK: Android
#if __CC_PLATFORM_ANDROID

-(void)setupAndroid
{
    [CCFileLocator sharedFileLocator].searchPaths = [@[
        [[NSBundle mainBundle] pathForResource:@"Published-Android" ofType:nil],
    ] arrayByAddingObjectsFromArray:[CCFileLocator sharedFileLocator].searchPaths];
    
    [super setupAndroid];
}

#endif


//MARK: Mac
#if __CC_PLATFORM_MAC

-(void)setupMac
{
    [CCFileLocator sharedFileLocator].searchPaths = [@[
        [[NSBundle mainBundle] pathForResource:@"Published-iOS" ofType:nil],
    ] arrayByAddingObjectsFromArray:[CCFileLocator sharedFileLocator].searchPaths];
    
    [super setupMac];
}

-(CGSize)defaultWindowSize
{
    return CGSizeMake(480.0f, 320.0f);
}

#endif

@end