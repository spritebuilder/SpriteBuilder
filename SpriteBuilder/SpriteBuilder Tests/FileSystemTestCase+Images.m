#import "FileSystemTestCase+Images.h"

@implementation FileSystemTestCase (Images)

- (void)createPNGAtPath:(NSString *)relFilePath width:(NSUInteger)width height:(NSUInteger)height;
{
    [self createIntermediateDirectoriesForFilPath:relFilePath];

    NSString *pngFullPath = [self fullPathForFile:relFilePath];
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

    CFURLRef url = (__bridge CFURLRef) [NSURL fileURLWithPath:pngFullPath];
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, NULL);
    CGImageDestinationAddImage(destination, myImage, nil);

    if (!CGImageDestinationFinalize(destination))
    {
        XCTFail(@"Failed to write image to %@", pngFullPath);
    }

    CGContextRelease (context);
    CGImageRelease(myImage);
}

- (void)assertPNGAtPath:(NSString *)relFilePath hasWidth:(NSUInteger)expectedWidth hasHeight:(NSUInteger)expectedHeight
{
    NSString *fullPath = [self fullPathForFile:relFilePath];

    CGDataProviderRef dataProvider = CGDataProviderCreateWithFilename(fullPath.UTF8String);
    CGImageRef image = CGImageCreateWithPNGDataProvider(dataProvider, NULL, NO, kCGRenderingIntentDefault);

    [self assertImageAtPath:fullPath
                   hasWidth:expectedWidth
                  hasHeight:expectedHeight
                  extension:@"PNG"
                   imageRef:image];
}

- (void)assertJPGAtPath:(NSString *)relFilePath hasWidth:(NSUInteger)expectedWidth hasHeight:(NSUInteger)expectedHeight
{
    NSString *fullPath = [self fullPathForFile:relFilePath];

    CGDataProviderRef dataProvider = CGDataProviderCreateWithFilename(fullPath.UTF8String);
    CGImageRef image = CGImageCreateWithJPEGDataProvider(dataProvider, NULL, NO, kCGRenderingIntentDefault);

    [self assertImageAtPath:fullPath
                   hasWidth:expectedWidth
                  hasHeight:expectedHeight
                  extension:@"JPG"
                   imageRef:image];
}

- (void)assertImageAtPath:(NSString *)fullPath
                 hasWidth:(NSUInteger)expectedWidth
                hasHeight:(NSUInteger)expectedHeight
                extension:(NSString *)extension
                 imageRef:(CGImageRef)imageRef
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:fullPath])
    {
        XCTFail(@"%@ file does not exist, cannot test dimensions at path \"%@\"", extension, fullPath);
        return;
    }

    NSUInteger imgHeight = CGImageGetHeight(imageRef);
    NSUInteger imgWidth = CGImageGetWidth(imageRef);

    XCTAssertEqual(imgWidth, expectedWidth, @"%@'s width of %lu does not match %lu at path %@", extension, imgWidth, expectedWidth, fullPath);
    XCTAssertEqual(imgHeight, expectedHeight, @"%@'s height of %lu does not match %lu at path %@", extension, imgHeight, expectedHeight, fullPath);
}

@end