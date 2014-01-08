//
//  SoundFileImageController.h
//  SpriteBuilder
//
//  Created by John Twigg on 2013-11-20.
//
//

#import <Foundation/Foundation.h>

extern NSString * kSoundFileImageLoaded;

@interface WaveformImageCell : NSImageCell

@property (retain) NSString * fileName;
@end

@interface SoundFileImageController : NSObject
{
    NSMutableDictionary * soundFileImages;

}

+(SoundFileImageController*)sharedInstance;

//Get the size of the file.
-(NSTimeInterval)getFileDuration:(NSString *)fileName;

//Render the audio image the cell frame.
-(void)drawFrame:(NSString *)fileName withFrame:(CGRect)cellFrame;

//Get an indentifier based on the image size.
-(NSString*)sizeIdentifier:(CGSize)size;

//Round up the iamge size to the nearest power of 2.
-(CGSize)roundImageSize:(CGSize)size;

//Get the cached properties for the given sound file. 
-(NSMutableDictionary*)getSoundFileProperties:(NSString*)fileName;

@end
