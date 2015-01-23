//
//  PROJECTIDENTIFIERController.m
//  PROJECTNAME
//


#import "PROJECTIDENTIFIERController.h"

static PROJECTIDENTIFIERController *__sharedController;

@implementation PROJECTIDENTIFIERController

+ (PROJECTIDENTIFIERController*)sharedController
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
                  {
                      __sharedController = [[PROJECTIDENTIFIERController alloc] init];
                  });
    
    return __sharedController;
}

+ (void)setupApplication
{
    static dispatch_once_t setupToken;
    dispatch_once(&setupToken, ^
                  {
                      [[PROJECTIDENTIFIERController sharedController] setupApplication];
                  });
}


- (NSString *)firstSceneName
{
    return @"MainScene";
}

@end