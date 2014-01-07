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
        soundFileImages = [[NSMutableDictionary alloc] init];
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
    SInt32 max;
    SInt32 min;
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
    
    UInt32 sampleRate,channelCount;
    
    NSArray* formatDesc = songTrack.formatDescriptions;
    for(unsigned int i = 0; i < [formatDesc count]; ++i) {
        CMAudioFormatDescriptionRef item = (__bridge CMAudioFormatDescriptionRef)[formatDesc objectAtIndex:i];
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
    
    
    
    struct MaxMin maxSample = {-99999,99999};
    
    
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

            @autoreleasepool {
            
                NSMutableData * data = [NSMutableData dataWithLength:length];
                CMBlockBufferCopyDataBytes(blockBufferRef, 0, length, data.mutableBytes);
                
                SInt16 * samples = (SInt16 *) data.mutableBytes;
                int sampleCount = (UInt32)length / bytesPerSample;
                
                for (int i = 0; i < sampleCount ; i ++) {
                    sampleTotal++;
                    SInt16 left = *samples++;

                    
                    if(left  > maxSample.max)
                        maxSample.max = left;
                    
                    if(left  < maxSample.min)
                        maxSample.min = left;
                    
                    
                    SInt16 right;
                    if (channelCount==2) {
                        right = *samples++;
                        if(right  > maxSample.max)
                            maxSample.max = right;
                        
                        if(right  < maxSample.min)
                            maxSample.min = right;
                    }
                    
                    sampleTally++;
                    
                    if (sampleTally > samplesPerPixel  ) {
                        
                        
                        if (abs(maxSample.max) > normalizeMax) {
                            normalizeMax = abs(maxSample.max);
                        }
                        
                        if (abs(maxSample.min) > normalizeMax) {
                            normalizeMax = abs(maxSample.min);
                        }
                        
                        
                        [fullSongData appendBytes:&maxSample.max length:sizeof(maxSample.max)];
                        [fullSongData appendBytes:&maxSample.min length:sizeof(maxSample.min)];
                        
                        
                        maxSample.max = 0;
                        maxSample.min = 0;

                        sampleTally = 0;
                        
                    }
                }
            
            }
            
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
        
        waveformImage = [self audioImageGraph:(SInt32 *)fullSongData.bytes
                                 normalizeMax:normalizeMax
                                  sampleCount:fullSongData.length / sizeof(MaxMin)
                                  imageHeight:size.height];
    }
    
    
    return waveformImage;
}


-(NSImage *) audioImageGraph:(SInt32 *) samples
                normalizeMax:(SInt16) normalizeMax
                 sampleCount:(NSInteger) sampleCount
                 imageHeight:(float) imageHeight {
    
    CGSize imageSize = CGSizeMake(sampleCount, imageHeight);
    
    
    NSBitmapImageRep *offscreenRep = [[NSBitmapImageRep alloc]
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
                                       bitsPerPixel:0];
    
    NSGraphicsContext * graphicsContext = [NSGraphicsContext graphicsContextWithBitmapImageRep:offscreenRep];
    
    CGContextRef context = [graphicsContext graphicsPort];
    
    CGRect rect;
    rect.size = imageSize;
    rect.origin.x = 0;
    rect.origin.y = 0;
    

    
    float halfGraphHeight = (imageHeight / 2) ;
    float centerLeft = halfGraphHeight;
    float sampleAdjustmentFactor = (imageHeight) / (float) normalizeMax / 2.0f;
    
    SInt32 * samplePtr = samples;
    
    CGPoint * points = malloc(sizeof(CGPoint) * sampleCount * 2);
    
    CGPoint * current = points;
    for (NSInteger intSample = 0 ; intSample < sampleCount ; intSample ++ ) {
        SInt32 leftMax = *samplePtr++;
        samplePtr++;
        
        float pixelsMax = (float) leftMax * sampleAdjustmentFactor;

        current->x = intSample;
        current->y = centerLeft+ pixelsMax;
        current++;
        
    }
    
    samplePtr = samples + sampleCount * 2;
    for (NSInteger intSample = sampleCount -1; intSample >= 0 ; intSample-- )
    {
        SInt32 leftMin = *--samplePtr;
        samplePtr--;
        
        float pixelsMin = (float)leftMin * sampleAdjustmentFactor;
        
        current->x = intSample;
        current->y = centerLeft+ pixelsMin;
        current++;
        
    }
    
    CGContextClearRect(context, rect);
    
    CGContextSetAlpha(context,1.0);
    CGContextSetFillColorWithColor(context, [NSColor blueColor].CGColor);
    CGContextSetLineWidth(context, 1.0);
    
    CGMutablePathRef mutablePath = CGPathCreateMutable();
    CGPathAddLines(mutablePath, nil, points, sampleCount * 2);
    
    CGPathCloseSubpath(mutablePath);

    CGContextBeginPath(context);
    CGContextAddPath(context, mutablePath);
    CGContextClosePath( context ); //ensure path is closed, not necessary if you know it is
    CGPathDrawingMode mode = kCGPathFill;
    CGContextDrawPath( context, mode );
    
    CFRelease(mutablePath);
    free(points);
   
    
    [NSGraphicsContext restoreGraphicsState];
    
    NSImage *img = [[NSImage alloc] initWithSize:imageSize];
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
    
    NSImage *image = [[NSImage alloc] initWithSize:size];
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
