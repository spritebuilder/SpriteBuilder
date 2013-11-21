//
//  SoundFileImageController.m
//  SpriteBuilder
//
//  Created by John Twigg on 2013-11-20.
//
//

#import "SoundFileImageController.h"
#import <AVFoundation/AVFoundation.h>

NSString * kSoundFileImageLoaded = @"kSoundFileImageLoaded";

@implementation SoundFileImageController

-(id)init
{
    self = [super init];
    if(self)
    {
        soundFileImages = [[[NSMutableDictionary alloc] init] retain];
        soundFileImages[@"_default_"] =[[NSMutableDictionary alloc] init];

    }
    return self;
}

+(SoundFileImageController*)sharedInstance
{
    static dispatch_once_t once = 0L;
    static SoundFileImageController *sharedInstance = nil;
    dispatch_once(&once, ^{
        sharedInstance = [[SoundFileImageController alloc] init];
    });
    
    return sharedInstance;
}

#pragma mark Audio Display

struct MaxMin
{
    SInt16 max;
    SInt16 min;
};
typedef struct MaxMin MaxMin;

- (NSImage *) renderImageForAudioAsset:(NSString *)fileName  withSize:(CGSize)size
{
    
    AVURLAsset *audioAssets = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:fileName]];
    
    NSError * error = nil;
    AVAssetReader * reader = [[AVAssetReader alloc] initWithAsset:audioAssets error:&error];
    if(reader == nil)
    {
        return [self defaultImage:size];
    }
    AVAssetTrack * songTrack = [audioAssets.tracks objectAtIndex:0];
    
    NSDictionary* outputSettingsDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                                        
                                        [NSNumber numberWithInt:kAudioFormatLinearPCM],AVFormatIDKey,
                                        //     [NSNumber numberWithInt:44100.0],AVSampleRateKey, /*Not Supported*/
                                        //     [NSNumber numberWithInt: 2],AVNumberOfChannelsKey,    /*Not Supported*/
                                        
                                        [NSNumber numberWithInt:16],AVLinearPCMBitDepthKey,
                                        [NSNumber numberWithBool:NO],AVLinearPCMIsBigEndianKey,
                                        [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
                                        [NSNumber numberWithBool:NO],AVLinearPCMIsNonInterleaved,
                                        
                                        nil];
    
    
    AVAssetReaderTrackOutput* output = [[AVAssetReaderTrackOutput alloc] initWithTrack:songTrack outputSettings:outputSettingsDict];
    
    [reader addOutput:output];
    [output release];
    
    UInt32 sampleRate,channelCount;
    
    NSArray* formatDesc = songTrack.formatDescriptions;
    for(unsigned int i = 0; i < [formatDesc count]; ++i) {
        CMAudioFormatDescriptionRef item = (CMAudioFormatDescriptionRef)[formatDesc objectAtIndex:i];
        const AudioStreamBasicDescription* fmtDesc = CMAudioFormatDescriptionGetStreamBasicDescription (item);
        if(fmtDesc ) {
            
            sampleRate = fmtDesc->mSampleRate;
            channelCount = fmtDesc->mChannelsPerFrame;
            
            //    NSLog(@"channels:%u, bytes/packet: %u, sampleRate %f",fmtDesc->mChannelsPerFrame, fmtDesc->mBytesPerPacket,fmtDesc->mSampleRate);
        }
    }
    
    
    UInt32 bytesPerSample = 2 * channelCount;
    SInt16 normalizeMax = 0;
    
    NSMutableData * fullSongData = [[NSMutableData alloc] init];
    [reader startReading];
    
    
    
    struct MaxMin maxLeft = {0,0};
    struct MaxMin maxRight = {0,0};
    
    
    NSInteger sampleTally = 0;
    UInt64 sampleTotal = 0;
    
    UInt64 duration =(UInt32)reader.asset.duration.value;
    
    NSInteger samplesPerPixel = duration / size.width;
    
    while (reader.status == AVAssetReaderStatusReading){
        
        AVAssetReaderTrackOutput * trackOutput = (AVAssetReaderTrackOutput *)[reader.outputs objectAtIndex:0];
        CMSampleBufferRef sampleBufferRef = [trackOutput copyNextSampleBuffer];
        
        if (sampleBufferRef){
            CMBlockBufferRef blockBufferRef = CMSampleBufferGetDataBuffer(sampleBufferRef);
            
            size_t length = CMBlockBufferGetDataLength(blockBufferRef);

            NSAutoreleasePool *wader = [[NSAutoreleasePool alloc] init];
            
            NSMutableData * data = [NSMutableData dataWithLength:length];
            CMBlockBufferCopyDataBytes(blockBufferRef, 0, length, data.mutableBytes);
            
            SInt16 * samples = (SInt16 *) data.mutableBytes;
            int sampleCount = (UInt32)length / bytesPerSample;
            
            for (int i = 0; i < sampleCount ; i ++) {
                sampleTotal++;
                SInt16 left = *samples++;

                
                if(left  > maxLeft.max)
                    maxLeft.max = left;
                
                if(left  < maxLeft.min)
                    maxLeft.min = left;
                
                
                SInt16 right;
                if (channelCount==2) {
                    right = *samples++;
                    if(right  > maxRight.max)
                        maxRight.max = right;
                    
                    if(right  < maxRight.min)
                        maxRight.min = right;
                }
                
                sampleTally++;
                
                if (sampleTally > samplesPerPixel  ) {
                    
                    
                    if (abs(maxLeft.max) > normalizeMax) {
                        normalizeMax = abs(maxLeft.max);
                    }
                    
                    if (abs(maxLeft.min) > normalizeMax) {
                        normalizeMax = abs(maxLeft.min);
                    }
                    
                    
                    [fullSongData appendBytes:&maxLeft.max length:sizeof(maxLeft.max)];
                    [fullSongData appendBytes:&maxLeft.min length:sizeof(maxLeft.min)];
                    
                    if (channelCount==2) {
                        
                        if (abs(maxRight.max) > normalizeMax) {
                            normalizeMax = abs(maxRight.max);
                        }
                        
                        if (abs(maxRight.min) > normalizeMax) {
                            normalizeMax = abs(maxRight.min);
                        }
                        
                        [fullSongData appendBytes:&maxRight.max length:sizeof(maxRight.max)];
                        [fullSongData appendBytes:&maxRight.min length:sizeof(maxRight.min)];
                    }
                    
                    maxLeft.max = 0;
                    maxLeft.min = 0;

                    maxRight.max = 0;
                    maxRight.min = 0;

                    sampleTally = 0;
                    
                }
            }
            
            [wader drain];
            
            CMSampleBufferInvalidate(sampleBufferRef);
            
            CFRelease(sampleBufferRef);
        }
    }
    
    
    NSImage *waveformImage = nil;
    
    if (reader.status == AVAssetReaderStatusFailed || reader.status == AVAssetReaderStatusUnknown){
        // Something went wrong. return nil
        return nil;
    }
    
    if (reader.status == AVAssetReaderStatusCompleted){
        
        waveformImage = [self audioImageGraph:(SInt16 *)fullSongData.bytes
                                 normalizeMax:normalizeMax
                                  sampleCount:fullSongData.length / (4 * channelCount)
                                 channelCount:channelCount
                                  imageHeight:size.height];
    }
    
    [fullSongData release];
    [reader release];
    
    return waveformImage;
}


-(NSImage *) audioImageGraph:(SInt16 *) samples
                normalizeMax:(SInt16) normalizeMax
                 sampleCount:(NSInteger) sampleCount
                channelCount:(NSInteger) channelCount
                 imageHeight:(float) imageHeight {
    
    CGSize imageSize = CGSizeMake(sampleCount, imageHeight);
    
    
    NSBitmapImageRep *offscreenRep = [[[NSBitmapImageRep alloc]
                                       initWithBitmapDataPlanes:NULL
                                       pixelsWide:sampleCount
                                       pixelsHigh:imageHeight
                                       bitsPerSample:8
                                       samplesPerPixel:4
                                       hasAlpha:YES
                                       isPlanar:NO
                                       colorSpaceName:NSDeviceRGBColorSpace
                                       bitmapFormat:NSAlphaFirstBitmapFormat
                                       bytesPerRow:0
                                       bitsPerPixel:0] autorelease];
    
    NSGraphicsContext * graphicsContext = [NSGraphicsContext graphicsContextWithBitmapImageRep:offscreenRep];
    
    CGContextRef context = [graphicsContext graphicsPort];
    
    CGRect rect;
    rect.size = imageSize;
    rect.origin.x = 0;
    rect.origin.y = 0;
    
    CGContextClearRect(context, rect);
    
    //CGContextSetFillColorWithColor(context, [NSColor blackColor].CGColor);
    CGContextSetAlpha(context,1.0);

    
    CGColorRef leftcolor = [[NSColor blueColor] CGColor];
    CGColorRef rightcolor = [[NSColor blueColor] CGColor];
    
    //CGContextFillRect(context, rect);
    
    CGContextSetLineWidth(context, 1.0);
    
    float halfGraphHeight = (imageHeight / 2) / (float) channelCount ;
    float centerLeft = halfGraphHeight;
    float centerRight = (halfGraphHeight*3) ;
    float sampleAdjustmentFactor = (imageHeight/ (float) channelCount) / (float) normalizeMax / 2.0f;
    
    for (NSInteger intSample = 0 ; intSample < sampleCount ; intSample ++ ) {
        SInt16 leftMax = *samples++;
        SInt16 leftMin = *samples++;
        
        float pixelsMax = (float) leftMax * sampleAdjustmentFactor;
        float pixelsMin = (float) leftMin * sampleAdjustmentFactor;
        

        CGContextMoveToPoint(context, intSample, centerLeft + pixelsMax);
        CGContextAddLineToPoint(context, intSample, centerLeft+ pixelsMin);
        
        CGContextSetStrokeColorWithColor(context, leftcolor);
        CGContextStrokePath(context);
        
        if (channelCount==2)
        {
            SInt16 rightMax = *samples++;
            SInt16 rightMin = *samples++;
            
            float pixelsMax = (float) rightMax * sampleAdjustmentFactor;
            float pixelsMin = (float) rightMin * sampleAdjustmentFactor;
            
            CGContextMoveToPoint(context, intSample, centerRight + pixelsMax);
            CGContextAddLineToPoint(context, intSample, centerRight+ pixelsMin);
            
            CGContextSetStrokeColorWithColor(context, rightcolor);
            CGContextStrokePath(context);
        }
    }
    
    [NSGraphicsContext restoreGraphicsState];
    
    NSImage *img = [[[NSImage alloc] initWithSize:imageSize] autorelease];
    [img addRepresentation:offscreenRep];
    
    return img;
}

-(NSString*)sizeIdentifier:(CGSize)size
{
    return  [NSString stringWithFormat:@"%f|%f", size.width, size.height];
}

-(void)queueImageRendering:(NSString*)fileName withSize:(CGSize)size
{
    NSMutableDictionary * images = [self getSoundFileProperties:fileName];
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        
        NSImage * image = [self renderImageForAudioAsset:fileName withSize:size];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            NSString* sizeIdentifier = [self sizeIdentifier:size];
            images[sizeIdentifier] = image;
            
            id userData = @{@"image":image, @"size":[self sizeIdentifier:size]};
            [[NSNotificationCenter defaultCenter] postNotificationName:kSoundFileImageLoaded object:images userInfo:userData];
            
        });
    });

}

static const int kMaxImageWidth = 1024 * 2;
static const int kMaxImageHeight = 256;
-(CGSize)roundImageSize:(CGSize)size
{

    int width = 8;
    while(width < size.width && width < kMaxImageWidth)
    {
        width *= 2;
    }
    
    int height = 8;
    while(height < size.height && height < kMaxImageHeight)
    {
        height *= 2;
    }
    
    return CGSizeMake(width, height);
    
}

-(NSImage*)generateDefaultImage:(CGSize)size
{
    
    NSImage *image = [[[NSImage alloc] initWithSize:size] autorelease];
    NSColor * color = [NSColor grayColor];
    [image lockFocusFlipped:YES];
    
    [color drawSwatchInRect:NSMakeRect(0, 0, size.width, size.height)];


    NSGraphicsContext* graphicsContext = [NSGraphicsContext currentContext];
    CGContextRef context = [graphicsContext graphicsPort];
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, 0.0f, size.height);
    CGContextScaleCTM(context, 1.0f, -1.0f);
    NSString * loadingText = @"Loading...";
    [loadingText drawAtPoint:CGPointMake(8, 3)withAttributes:nil];
    CGContextRestoreGState(context);
    
    [image unlockFocus];
    
    
    return image;
}

-(NSImage * )defaultImage:(CGSize)size
{
    NSMutableDictionary * images = soundFileImages[@"_default_"];
    
    NSString * sizeIdentifier = [self sizeIdentifier:size];
    
    if(images[sizeIdentifier] != nil)
        return images[sizeIdentifier];
    
    NSImage * defaultImage = [self generateDefaultImage:size];
    images[sizeIdentifier] = defaultImage;
    
    return defaultImage;
}

-(NSImage*)closestMatch:(NSString*)fileName withSize:(CGSize)size
{
    NSMutableDictionary * images = [self getSoundFileProperties:fileName];
    
    NSImage * closestMatch = nil;
    
    float targetArea = size.height * size.width;
    
    for(id obj in images.allValues)
    {
        if([obj isKindOfClass:[NSImage class]])
        {
            NSImage * image = obj;
            
            if(closestMatch == nil)
            {
                closestMatch = image;
                continue;
            }
            
            float closestArea = closestMatch.size.height * closestMatch.size.width;
            float currentArea = image.size.height * image.size.width;
            
            if(abs(closestArea - targetArea) > abs(currentArea - targetArea))
            {
                closestMatch = image;
            }
        }
    }
 
    if(closestMatch == nil)
    {
        NSString * sizeIdentifier = [self sizeIdentifier:size];
        closestMatch =  [self defaultImage:size];
        images[sizeIdentifier] = closestMatch;
    }
    
    return closestMatch;
}

-(NSMutableDictionary*)getSoundFileProperties:(NSString*)fileName
{
    
    NSMutableDictionary * images = [soundFileImages objectForKey:fileName];
    if(images == nil)
    {
        images = [[NSMutableDictionary alloc] init];
        soundFileImages[fileName] = images;
    }

    return images;
}

-(NSImage*)loadImage:(NSString*)fileName withSize:(CGSize)size
{
    CGSize roundedSize = [self roundImageSize:size];

    
    if(soundFileImages[fileName] == nil)
    {
        [self queueImageRendering:fileName withSize:roundedSize];
        return [self closestMatch:fileName withSize:roundedSize];
    }
    
    NSMutableDictionary * images = soundFileImages[fileName];
    
    NSString * sizeIdentifier = [self sizeIdentifier:roundedSize];
    
    if(images[sizeIdentifier] == nil)
    {
        [self queueImageRendering:fileName withSize:roundedSize];
        return [self closestMatch:fileName withSize:roundedSize];
    }
    
    NSImage * waveformImage = images[sizeIdentifier];
    
    return waveformImage;
}

-(NSTimeInterval)getFileDuration:(NSString *)fileName
{
    NSMutableDictionary * soundFileProperties = [self getSoundFileProperties:fileName];
    
    if(soundFileProperties[@"_duration_"] == nil)
    {
        
        AVURLAsset *audioAssets = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:fileName]];
        CMTime audioDuration = audioAssets.duration;
        float audioDurationSeconds = CMTimeGetSeconds(audioDuration);
        
        soundFileProperties[@"_duration_"] = @(audioDurationSeconds);
    }
    
    return [(NSNumber*)soundFileProperties[@"_duration_"] floatValue];
}


-(void)drawFrame:(NSString *)fileName withFrame:(CGRect)cellFrame
{
    NSImage * image = [self loadImage:fileName withSize:cellFrame.size];
    
    [image drawInRect:cellFrame fromRect:CGRectZero operation:NSCompositeSourceOver fraction:1];
}
@end
