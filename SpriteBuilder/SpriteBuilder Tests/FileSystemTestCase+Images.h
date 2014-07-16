#import <Foundation/Foundation.h>
#import "FileSystemTestCase.h"

@interface FileSystemTestCase (Images)


// Creates a non transparent random colored png at the given path with the given dimensions. Path has to relative to the testing folder
// Will XCTFail if there was an error
- (void)createPNGAtPath:(NSString *)relFilePath width:(NSUInteger)width height:(NSUInteger)height;

// Creates a png at the given path with the given dimensions and color(for debugging). Path has to relative to the testing folder
// Will XCTFail if there was an error
- (void)createPNGAtPath:(NSString *)relFilePath width:(NSUInteger)width height:(NSUInteger)height color:(NSColor *)color;

// Asserts a width and a height for a PNG file. If file does not exist at given path method will XCTFail
- (void)assertPNGAtPath:(NSString *)relFilePath hasWidth:(NSUInteger)expectedWidth hasHeight:(NSUInteger)height;

// Asserts a width and a height for a JPG file. If file does not exist at given path method will XCTFail
- (void)assertJPGAtPath:(NSString *)relFilePath hasWidth:(NSUInteger)expectedWidth hasHeight:(NSUInteger)expectedHeight;

@end