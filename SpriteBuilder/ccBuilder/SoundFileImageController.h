//
//  SoundFileImageController.h
//  SpriteBuilder
//
//  Created by John Twigg on 2013-11-20.
//
//

#import <Foundation/Foundation.h>


@interface SoundFileImageController : NSObject
{
    NSMutableDictionary * soundFileImages;
}

+(SoundFileImageController*)sharedInstance;
-(NSTimeInterval)getFileDuration:(NSString *)fileName;
-(void)drawFrame:(NSString *)fileName withFrame:(CGRect)cellFrame;

@end
