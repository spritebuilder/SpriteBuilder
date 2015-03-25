//
//  PROJECTIDENTIFIERSetup.m
//  PROJECTNAME
//


#import "PROJECTIDENTIFIERSetup.h"


@implementation PROJECTIDENTIFIERSetup

-(NSDictionary *)setupConfig
{
    //  Loads configCocos2D.plist from disk or returns an empty dictionary if it doesn't exist.
    NSMutableDictionary *config = [[super setupConfig] mutableCopy];
    
    // Add custom overrides to the cocosConfig.plist file here.
    [config addEntriesFromDictionary:@{
//        CCSetupShowDebugStats: @(YES),
//        CCSetupFixedUpdateInterval: @(1.0/120.0),
    }];
    
    return config;
}

- (void)setupCommon
{
    // Cross platform app setup code goes here.
    
    // If the project is being used with SpriteBuilder, you'll need some extra search paths, etc.
    [self setupForSpriteBuilder];
}

-(CCScene *)createFirstScene
{
    // This method is responsible for creating and returning the initial scene when the app starts up.
    return [CCBReader loadAsScene:@"MainScene"];
}

#if __CC_PLATFORM_IOS

-(void)setupApplication
{
    [self setupCommon];
    
    // Your iOS specific setup code goes here.
    
    [super setupApplication];
}

#endif

#if __CC_PLATFORM_ANDROID

-(void)setupApplication
{
    [self setupCommon];
    
    // Your Android specific setup code goes here.
    
    [super setupApplication];
}

#endif

#if __CC_PLATFORM_MAC

-(void)setupApplication
{
    [self setupCommon];
    
    // Your Mac specific setup code goes here.
    
    [super setupApplication];
}

#endif

@end