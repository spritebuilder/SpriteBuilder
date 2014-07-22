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
#import "CCBPublishDelegate.h"
#import "CCBWarnings.h"
#import "CCBPublisherTypes.h"

@protocol TaskStatusUpdaterProtocol;
@class ProjectSettings;
@class CCBWarnings;
@class CCBDirectoryPublisher;
@class PublishRenamedFilesLookup;
@class DateCache;
@class PublishingTaskStatusProgress;


@interface CCBDirectoryPublisher : NSObject

@property (nonatomic, copy) NSString *inputDir;
@property (nonatomic, copy) NSString *outputDir;
@property (nonatomic) CCBPublisherOSType osType;
@property (nonatomic) NSInteger audioQuality;
@property (nonatomic, weak) NSArray *resolutions;
@property (nonatomic, weak) NSMutableSet *publishedPNGFiles;
@property (nonatomic, weak) NSMutableSet *publishedSpriteSheetFiles;
@property (nonatomic, weak) PublishRenamedFilesLookup *renamedFilesLookup;
@property (nonatomic, strong) DateCache *modifiedDatesCache;
@property (nonatomic, weak) PublishingTaskStatusProgress *publishingTaskStatusProgress;

- (id)initWithProjectSettings:(ProjectSettings *)someProjectSettings warnings:(CCBWarnings *)someWarnings queue:(NSOperationQueue *)queue;

- (BOOL)generateAndEnqueuePublishingTasks;

@end
