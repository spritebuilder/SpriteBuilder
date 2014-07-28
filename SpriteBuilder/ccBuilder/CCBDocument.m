/*
 * CocosBuilder: http://www.cocosbuilder.com
 *
 * Copyright (c) 2011 Viktor Lidholt
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

#import "CCBDocument.h"
#import "CocosScene.h"

@implementation CCBDocument

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.undoManager = [[NSUndoManager alloc] init];
		self.stageZoom = 1;
		self.stageScrollOffset = ccp(0,0);
		self.stageColor = kCCBCanvasColorBlack;
		self.UUID = 0x1; //Starts at One!
	}
    
    return self;
}

- (instancetype)initWithContentsOfFile:(NSString *)filePath
{
    self = [self init];

    if (self)
    {
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithContentsOfFile:filePath];

        self.filePath = filePath;
        self.data = dictionary;
        self.exportPath = [dictionary objectForKey:@"exportPath"];
        self.exportPlugIn = [dictionary objectForKey:@"exportPlugIn"];
        self.UUID = [dictionary[@"UUID"] unsignedIntegerValue];

        [self fixupUUID];
    }

    return self;
}

- (void)fixupUUID
{
    //If UUID is unset, it means the doc is out of date. Fixup.
    if (_UUID == 0x0)
    {
        self.UUID = 0x1;
        [self fixupUUIDWithDict:_data[@"nodeGraph"]];
    }
}

-(void)fixupUUIDWithDict:(NSMutableDictionary*)dict
{
    if(!dict[@"UUID"])
    {
        dict[@"UUID"] = @(_UUID);
        self.UUID = _UUID + 1;
    }

    if(dict[@"children"])
    {
        for (NSMutableDictionary * child in dict[@"children"])
        {
            [self fixupUUIDWithDict:child];
        }
    }
}

- (NSString*) formattedName
{
    return [[_filePath lastPathComponent] stringByDeletingPathExtension];
}

- (NSString*) rootPath
{
    return [_filePath stringByDeletingLastPathComponent];
}

- (void)setPath:(NSString *)newPath
{
    if (![newPath isEqualToString:_filePath])
    {
        _filePath = newPath;
    }
}

- (BOOL)isWithinPath:(NSString *)path
{
    return [_filePath hasPrefix:path];
}

- (BOOL)store
{
    return [_data writeToFile:_filePath atomically:YES];
}

- (NSUInteger)getAndIncrementUUID
{
	NSUInteger current = self.UUID;
	self.UUID = self.UUID + 1;
	return current;
}

@end
