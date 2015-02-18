#import "AssertionAddons.h"

#import <XCTest/XCTest.h>

@implementation AssertionAddons

+ (void)assertArraysAreEqualIgnoringOrder:(NSArray *)arrayA arrayB:(NSArray *)arrayB
{
    NSMutableArray *arrayAMutable = [arrayA mutableCopy];
    NSMutableArray *arrayBMutable = [arrayB mutableCopy];

    NSSortDescriptor *highestToLowest = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:NO];
    [arrayAMutable sortUsingDescriptors:@[highestToLowest]];
    [arrayBMutable sortUsingDescriptors:@[highestToLowest]];

    XCTAssertEqualObjects(arrayAMutable, arrayBMutable);
}

+ (void)assertEqualObjectsWithDiff:(id)objectA objectB:(id)objectB
{
    BOOL equal = [objectA isEqualTo:objectB];
    XCTAssertTrue(equal);
    if (equal)
    {
        return;
    }

    NSTask *task = [[NSTask alloc] init];
    [task setCurrentDirectoryPath:NSTemporaryDirectory()];
    [task setLaunchPath:@"/bin/bash"];

    NSArray *args = @[@"-c", [NSString stringWithFormat:@"/usr/bin/diff <(echo \"%@\") <(echo \"%@\")", objectA, objectB]];
    [task setArguments:args];

    @try
    {
        [task launch];
        [task waitUntilExit];
    }
    @catch (NSException *exception)
    {
        NSLog(@"[COCO2D-UPDATER] [ERROR] unzipping failed: %@", exception);
    }
}

@end
