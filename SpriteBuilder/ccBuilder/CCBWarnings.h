/*
 * CocosBuilder: http://www.cocosbuilder.com
 *
 * Copyright (c) 2012 Zynga Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import <Foundation/Foundation.h>
#import "CCBPublisherTypes.h"

@interface CCBWarning : NSObject
{
    NSString* message;
    NSString* relatedFile;
    NSString* resolution;
    
    BOOL fatal;
}
@property (nonatomic,copy) NSString* message;
@property (nonatomic,copy) NSString* relatedFile;
@property (nonatomic) CCBPublisherOSType osType;
@property (nonatomic,copy) NSString* resolution;
@property (nonatomic,readonly) NSString* description;

@property (nonatomic,assign) BOOL fatal;

@end

@interface CCBWarnings : NSObject
{
    NSString* warningsDescription;
    NSMutableDictionary* warningsFiles;
    
    CCBPublisherOSType currentOSType;
}
@property (nonatomic,readonly) NSMutableArray* warnings;
@property (nonatomic,copy) NSString* warningsDescription;
@property (nonatomic,assign) CCBPublisherOSType currentOSType;

- (void) addWarningWithDescription:(NSString*)description isFatal:(BOOL)fatal relatedFile:(NSString*) relatedFile resolution:(NSString*) resolution;
- (void) addWarningWithDescription:(NSString*)description isFatal:(BOOL)fatal relatedFile:(NSString*) relatedFile;
- (void) addWarningWithDescription:(NSString*)description isFatal:(BOOL)fatal;
- (void) addWarningWithDescription:(NSString*)description;
- (void) addWarning:(CCBWarning*)warning;

- (NSArray*) warningsForRelatedFile:(NSString*) relatedFile;

@end
