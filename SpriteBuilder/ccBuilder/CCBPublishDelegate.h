//
//  CCBPublishDelegate.h
//  SpriteBuilder
//
//  Created by John Twigg on 1/23/14.
//
//

@protocol CCBPublishDelegate <NSObject>

@required
- (void)addWarningWithDescription:(NSString *)description
                          isFatal:(BOOL)fatal
                      relatedFile:(NSString *)relatedFile
                       resolution:(NSString *)resolution;

@end