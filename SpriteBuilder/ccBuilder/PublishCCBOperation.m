#import "PublishCCBOperation.h"
#import "PlugInManager.h"
#import "PlugInExport.h"
#import "CCBWarnings.h"
#import "NSArray+Query.h"
#import "ProjectSettings.h"
#import "CCBFileUtil.h"
#import "PublishingTaskStatusProgress.h"


@interface PublishCCBOperation ()

@property (nonatomic, copy) NSString *currentWorkingFile;

@end

@implementation PublishCCBOperation

- (void)main
{
    NSLog(@"[%@] %@", [self class], [self description]);

    [self publishCCB];

    [_publishingTaskStatusProgress taskFinished];
}

- (void)publishCCB
{
    if ([self.dstFile isEqualToString:self.filePath])
    {
        [_warnings addWarningWithDescription:@"Publish will overwrite files in resource directory." isFatal:YES];
        return;
    }

    NSDate *srcDate = [CCBFileUtil modificationDateForFile:self.filePath];
    NSDate *dstDate = [CCBFileUtil modificationDateForFile:self.dstFile];

    if (![srcDate isEqualToDate:dstDate])
    {
        [_publishingTaskStatusProgress updateStatusText:[NSString stringWithFormat:@"Publishing %@...", self.fileName]];

        // Remove old file
        NSFileManager *fileManager = [NSFileManager defaultManager];;
        [fileManager removeItemAtPath:self.dstFile error:NULL];

        BOOL sucess = [self publishCCBFile:self.filePath to:self.dstFile];
        if (!sucess)
        {
            return;
        }

        [CCBFileUtil setModificationDate:srcDate forFile:self.dstFile];
    }
}

- (BOOL)publishCCBFile:(NSString *)srcFile to:(NSString *)dstFile
{
    self.currentWorkingFile = [dstFile lastPathComponent];

    NSString *publishFormat = [_projectSettings.exporter copy];
    PlugInExport *plugIn = [[PlugInManager sharedManager] plugInExportForExtension:publishFormat];
    if (!plugIn)
    {
        [_warnings addWarningWithDescription:[NSString stringWithFormat:@"Plug-in is missing for publishing files to %@-format. You can select plug-in in Project Settings.", publishFormat] isFatal:YES];
        return NO;
    }

    // Load src file
    NSMutableDictionary *doc = [NSMutableDictionary dictionaryWithContentsOfFile:srcFile];
    if (!doc)
    {
        [_warnings addWarningWithDescription:[NSString stringWithFormat:@"Failed to publish ccb-file. File is in invalid format: %@", srcFile] isFatal:NO];
        return YES;
    }

    [self validateJointsInDocument:doc];

    // Export file
    plugIn.flattenPaths = _projectSettings.flattenPaths;
    plugIn.projectSettings = _projectSettings;
    plugIn.delegate = self;
    NSData *data = [plugIn exportDocument:doc];
    if (!data)
    {
        [_warnings addWarningWithDescription:[NSString stringWithFormat:@"Failed to publish ccb-file: %@", srcFile] isFatal:NO];
        return YES;
    }

    // Save file
    BOOL success = [data writeToFile:dstFile atomically:YES];
    if (!success)
    {
        [_warnings addWarningWithDescription:[NSString stringWithFormat:@"Failed to publish ccb-file. Failed to write file: %@", dstFile] isFatal:NO];
        return YES;
    }

    return YES;
}

- (void)validateJointsInDocument:(NSMutableDictionary *)document
{
    if (document[@"joints"])
    {
        NSMutableArray *joints = document[@"joints"];

        joints = [[joints filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSDictionary *joint, NSDictionary *bindings)
        {
            __block NSString *bodyType = @"bodyA";

            //Oh god. Nested blocks!
            PredicateBlock find = ^BOOL(NSDictionary *dict, int idx)
            {
                return [dict.allValues containsObject:bodyType];
            };

            //Find bodyA property
            if (![joint[@"properties"] findFirst:find])
            {
                NSString *description = [NSString stringWithFormat:@"Joint %@ must have bodyA attached. Not exporting it.", joint[@"displayName"]];
                [_warnings addWarningWithDescription:description isFatal:NO relatedFile:_currentWorkingFile];
                return NO;
            }

            //Find bodyB property
            bodyType = @"bodyB";
            if (![joint[@"properties"] findFirst:find])
            {
                NSString *description = [NSString stringWithFormat:@"Joint %@ must have a bodyB attached. Not exporting it.", joint[@"displayName"]];
                [_warnings addWarningWithDescription:description isFatal:NO relatedFile:_currentWorkingFile];
                return NO;
            }

            return YES;
        }]] mutableCopy];

        document[@"joints"] = joints;
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"file: %@, path: %@, dstfile: %@", _fileName, _filePath, _dstFile];
}


#pragma mark - CCBPublishDelegate methods

- (void)addWarningWithDescription:(NSString *)description isFatal:(BOOL)fatal relatedFile:(NSString *)relatedFile resolution:(NSString *)resolution
{
    [_warnings addWarningWithDescription:description isFatal:fatal relatedFile:relatedFile resolution:resolution];
}

- (BOOL)exportingToSpriteKit
{
    return (_projectSettings.engine == CCBTargetEngineSpriteKit);
}

@end