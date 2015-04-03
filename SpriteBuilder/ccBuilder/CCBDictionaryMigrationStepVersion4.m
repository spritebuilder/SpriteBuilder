#import <OCMock/OCMock.h>
#import "CCBDictionaryMigrationStepVersion4.h"
#import "CCBDictionaryKeys.h"
#import "NSError+SBErrors.h"
#import "Errors.h"
#import "CCBDocumentManipulator.h"


/*
    Version 4 to 5 changes:
    As of cocos2d v4 property blendFunc becomes blendMode and is stored in a dictionary now.

    Old format:
        <dict>
            <key>name</key>
            <string>blendFunc</string>
            <key>type</key>
            <string>Blendmode</string>
            <key>value</key>
            <array>
                <integer>774</integer>
                <integer>772</integer>
            </array>
        </dict>


    New format:
        <dict>
            <key>name</key>
            <string>blendMode</string>
            <key>type</key>
            <string>Blendmode</string>
            <key>value</key>
            <dict>
                <key>CCBlendFuncSrcColor</key>
                <integer>774</integer>
                <key>CCBlendFuncDstColor</key>
                <integer>772</integer>
                <key>CCBlendFuncSrcAlpha</key>
                <integer>774</integer>
                <key>CCBlendFuncDstAlpha</key>
                <integer>772</integer>
                <key>CCBlendEquationColor</key>
                <integer>32774</integer>
                <key>CCBlendEquationAlpha</key>
                <integer>32774</integer>
            </dict>
        </dict>
 */
@implementation CCBDictionaryMigrationStepVersion4

- (NSDictionary *)migrate:(NSDictionary *)ccb error:(NSError **)error
{
    if (!ccb)
    {
        [NSError setNewErrorWithErrorPointer:error code:SBCCBMigrationError message:@"CCB is nil"];
        return nil;
    }

    if (!ccb[CCB_DICTIONARY_KEY_NODEGRAPH])
    {
        [NSError setNewErrorWithErrorPointer:error code:SBCCBMigrationError message:@"Could not locate node graph in dictionary"];
        return nil;
    }

    NSMutableDictionary *mutableCCB = CFBridgingRelease(CFPropertyListCreateDeepCopy(NULL, (__bridge CFPropertyListRef)(ccb), kCFPropertyListMutableContainersAndLeaves));

    CCBDocumentManipulator *manipulator = [[CCBDocumentManipulator alloc] initWithDocument:mutableCCB];
    [manipulator processAllProperties:^NSDictionary *(NSDictionary *property, NSDictionary *child)
    {
        if ([property[CCB_DICTIONARY_KEY_PROPERTY_NAME] isEqualToString:@"blendFunc"])
        {
            return [self migrateOldBlendFuncToNewBlendMode:property];
        }
        return property;
    }];

    return mutableCCB;
}

- (NSDictionary *)migrateOldBlendFuncToNewBlendMode:(NSDictionary *)property
{
    id value = property[CCB_DICTIONARY_KEY_PROPERTY_VALUE];
    if ([value isKindOfClass:[NSArray class]]
        && ([value count] == 2))
    {
        return
            @{
                CCB_DICTIONARY_KEY_PROPERTY_NAME : @"blendMode",
                CCB_DICTIONARY_KEY_PROPERTY_TYPE : @"Blendmode",
                CCB_DICTIONARY_KEY_PROPERTY_VALUE : @{
                    @"CCBlendFuncSrcColor" : [value objectAtIndex:0],
                    @"CCBlendFuncSrcAlpha" : [value objectAtIndex:0],
                    @"CCBlendFuncDstAlpha" : [value objectAtIndex:1],
                    @"CCBlendFuncDstColor" : [value objectAtIndex:1],
                    @"CCBlendEquationColor" : @32774,
                    @"CCBlendEquationAlpha" : @32774
                }
            };
    }
    else
    {
        return property;
    }
}

@end
