#import "FileSystemTestCase+ProjectFixtures.h"
#import "CCBDictionaryKeys.h"


@implementation FileSystemTestCase (ProjectFixtures)

- (void)createCCBVersion4FileWithOldBlendFuncWithPath:(NSString *)path
{
    NSDictionary *ccb = [self ccbVersion4WithOldBlendFunc];
    [self createFilesWithContents:@{path : ccb}];
}

- (NSDictionary *)ccbVersion4WithOldBlendFunc
{
    return @{
        CCB_DICTIONARY_KEY_FILEVERSION : @4,
        CCB_DICTIONARY_KEY_NODEGRAPH : @{
            CCB_DICTIONARY_KEY_PROPERTIES : @[
                @{
                    CCB_DICTIONARY_KEY_PROPERTY_NAME : @"blendFunc",
                    CCB_DICTIONARY_KEY_PROPERTY_TYPE : @"Blendmode",
                    CCB_DICTIONARY_KEY_PROPERTY_VALUE : @[ @774, @772 ]
                }
            ],
            CCB_DICTIONARY_KEY_CHILDREN : @[
                @{
                    CCB_DICTIONARY_KEY_PROPERTIES : @[
                        // Should be ignored
                        @{
                            CCB_DICTIONARY_KEY_PROPERTY_NAME : @"Homer",
                            CCB_DICTIONARY_KEY_PROPERTY_TYPE : @"quote",
                            CCB_DICTIONARY_KEY_PROPERTY_VALUE : @"Duh!"
                        },
                        // Should not get migrated due to wrong value
                        @{
                            CCB_DICTIONARY_KEY_PROPERTY_NAME : @"blendFunc",
                            CCB_DICTIONARY_KEY_PROPERTY_TYPE : @"Blendmode",
                            CCB_DICTIONARY_KEY_PROPERTY_VALUE : @"Not an array!"
                        }
                    ]
                },
                @{
                    CCB_DICTIONARY_KEY_PROPERTIES : @[
                        @{
                            CCB_DICTIONARY_KEY_PROPERTY_NAME : @"blendFunc",
                            CCB_DICTIONARY_KEY_PROPERTY_TYPE : @"Blendmode",
                            CCB_DICTIONARY_KEY_PROPERTY_VALUE : @[ @769, @771 ]
                        }
                    ],
                }
            ]
        }
    };
}

- (void)createPackageSettingsVersion2WithPath:(NSString *)path
{
    NSDictionary *packageSettings = @{
        @"publishToCustomDirectory" : @YES,
        @"publishToZip" : @YES,
        @"osSettings" : @{
            @"ios": @{
                @"audio_quality":@7,
                @"resolutions":@[@"phone", @"phonehd", @"tablet", @"tablethd"]

            },
            @"android": @{
                @"audio_quality":@2,
                @"resolutions":@[@"phone", @"tablethd"]
            }
        },
        @"publishEnv" : @1,
        @"resourceAutoScaleFactor" : @-1,
        @"publishToMainProject" : @YES,
        @"outputDir" : @"asd"
    };

    [self createFilesWithContents:@{path : packageSettings}];
}

@end
