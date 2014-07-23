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

#import "CCBWarnings.h"

@implementation CCBWarning

@synthesize message;
@synthesize relatedFile;
@synthesize resolution;
@synthesize fatal;

+ (NSString*)formatOsType:(int)osType
{
    switch (osType)
    {
        case kCCBPublisherOSTypeHTML5: return @"HTML5";
        case kCCBPublisherOSTypeIOS: return @"iOS";
        case kCCBPublisherOSTypeAndroid: return @"Android";
        case kCCBPublisherOSTypeNone: return @"General";
        default: return @"undefined";
    }
}

@dynamic description;
- (NSString*) description
{
    NSString* resString = @"";
    if (self.resolution) resString = [NSString stringWithFormat:@" (%@)", self.resolution];
    
    NSString * relaventFile = @"";
    if(self.relatedFile) relaventFile = [NSString stringWithFormat:@" (%@)", self.relatedFile];
    
    
    return [NSString stringWithFormat:@"%@%@%@: %@", [CCBWarning formatOsType:self.osType], resString, relaventFile, self.message];
}

@end


@implementation CCBWarnings

@synthesize warningsDescription;
@synthesize currentOSType;

- (id) init
{
    self = [super init];
    if (!self) return NULL;
    
	_warnings = [NSMutableArray array];
    warningsFiles = [NSMutableDictionary dictionary];
    self.warningsDescription = @"Warnings";
    
    return self;
}

- (void) addWarningWithDescription:(NSString*)description isFatal:(BOOL)fatal
{
    [self addWarningWithDescription:description isFatal:fatal relatedFile:NULL];
}

- (void) addWarningWithDescription:(NSString*)description isFatal:(BOOL)fatal relatedFile:(NSString*) relatedFile
{
    [self addWarningWithDescription:description isFatal:fatal relatedFile:relatedFile resolution:NULL];
}

- (void) addWarningWithDescription:(NSString*)description isFatal:(BOOL)fatal relatedFile:(NSString*) relatedFile resolution:(NSString*) resolution
{
    CCBWarning* warning = [[CCBWarning alloc] init];
    warning.message = description;
    warning.relatedFile = relatedFile;
    warning.fatal = fatal;
    warning.resolution = resolution;
    [self addWarning:warning];
}

- (void) addWarningWithDescription:(NSString*)description
{
    CCBWarning* warning = [[CCBWarning alloc] init];
    warning.message = description;
    [self addWarning:warning];
}

- (void) addWarning:(CCBWarning*)warning
{
    warning.osType = currentOSType;
    
    [_warnings addObject:warning];
    NSLog(@"CCB WARNING: %@", warning.description);
    
    if (warning.relatedFile)
    {
        // Get warnings for the file
        NSMutableArray* ws = [warningsFiles objectForKey:warning.relatedFile];
        if (!ws)
        {
            ws = [NSMutableArray array];
            [warningsFiles setObject:ws forKey:warning.relatedFile];
        }
        
        [ws addObject:warning];
    }
}

- (NSArray*) warningsForRelatedFile:(NSString*) relatedFile
{
    return [warningsFiles objectForKey:relatedFile];
}


@end
