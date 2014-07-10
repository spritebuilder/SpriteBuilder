#import "FileSystemTestCase+Images.h"

@implementation FileSystemTestCase (Images)

- (void)createPNGAtPath:(NSString *)relFilePath width:(NSUInteger)width height:(NSUInteger)height;
{
    NSString *pngFilename = [self fullPathForFile:relFilePath];

    CGContextRef context = CGBitmapContextCreate(NULL,
                                                    width,
                                                    height,
                                                    8,
                                                    width*24,
                                                    CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB),
                                                    kCGImageAlphaNoneSkipLast);

    // red
    CGContextSetRGBFillColor (context, 1.0, 0.0, 0.0, 1.0);

    CGContextFillRect (context, CGRectMake (0, 0, width, height));
    CGImageRef myImage = CGBitmapContextCreateImage (context);

    CGContextDrawImage(context, CGRectMake (0, 0, width, height), myImage);

    CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:pngFilename];
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, NULL);
    CGImageDestinationAddImage(destination, myImage, nil);

    if (!CGImageDestinationFinalize(destination))
    {
        NSLog(@"Failed to write image to %@", pngFilename);
    }

    CGContextRelease (context);
    CGImageRelease(myImage);
}

- (void)assertPNGAtPath:(NSString *)relFilePath hasWidth:(NSUInteger)expectedWidth hasHeight:(NSUInteger)expectedHeight
{
    NSString *fullPath = [self fullPathForFile:relFilePath];

    CGDataProviderRef dataProvider = CGDataProviderCreateWithFilename(fullPath.UTF8String);
    CGImageRef image = CGImageCreateWithPNGDataProvider(dataProvider, NULL, NO, kCGRenderingIntentDefault);

    NSUInteger imgHeight = CGImageGetHeight(image);
    NSUInteger imgWidth = CGImageGetWidth(image);

    XCTAssertEqual(imgHeight, expectedHeight, @"Image's height does match. File's height %lu, expected %lu at path %@", imgHeight, expectedHeight, fullPath);
    XCTAssertEqual(imgWidth, expectedWidth, @"Image's width does match. File's width %lu, expected %lu at path %@", imgWidth, expectedWidth, fullPath);
}

@end