#import "PackageSettingsMigrator.h"
#import "NSError+SBErrors.h"
#import "Errors.h"
#import "PackageSettings.h"
#import "BackupFileCommand.h"

/*

Version 1
=========
* No version key set

<plist version="1.0">
<dict>
	<key>osSettings</key>
	<dict>
		<key>android</key>
		<dict>
			<key>audio_quality</key>
			<integer>4</integer>
			<key>resolutions</key>
			<array>
				<string>phone</string>
				<string>phonehd</string>
				<string>tablet</string>
				<string>tablethd</string>
			</array>
		</dict>
		<key>ios</key>
		<dict>
			<key>audio_quality</key>
			<integer>4</integer>
			<key>resolutions</key>
			<array>
				<string>phone</string>
				<string>phonehd</string>
				<string>tablet</string>
				<string>tablethd</string>
			</array>
		</dict>
	</dict>
	<key>outputDir</key>
	<string></string>
	<key>publishEnv</key>
	<integer>0</integer>
	<key>publishToCustomDirectory</key>
	<false/>
	<key>publishToMainProject</key>
	<true/>
	<key>publishToZip</key>
	<false/>
</dict>
</plist>


Version 2
=========
* NEW: resourceAutoScaleFactor added with integer type, still no version key

	<key>resourceAutoScaleFactor</key>
	<integer>4</integer>

Version 3
=========
* NEW: version key added with int value

* NEW: mainProjectResolutions, see also PublishResolutions class
    @[ @1, @2, @4 ]


* CHANGED: osSettings.android.resolutions and osSettings.iOS.resolutions changed to new format as in PublishResolutions, previously:
    @[
        @"phone", @"phonehd", @"tablet", @"tablethd"
    ]

    -> @[ @1, @2, @4 ]

* CHANGED: resourceAutoScaleFactor cannot be -1 anymore as global option has been removed, allowed values: 1, 2, 4. Default is 4 now

 */


@interface PackageSettingsMigrator ()

@property (nonatomic, copy) NSDictionary *packageSettings;
@property (nonatomic, copy, readwrite) NSDictionary *migratedPackageSettings;
@property (nonatomic, strong) NSError *migrationError;
@property (nonatomic) NSUInteger migrationVersionTarget;
@property (nonatomic) BackupFileCommand *backupFileCommand;
@property (nonatomic, copy) NSString *filepath;

@end


@implementation PackageSettingsMigrator

- (instancetype)initWithFilepath:(NSString *)filepath toVersion:(NSUInteger)toVersion
{
    NSAssert(filepath != nil, @"filepath must not be nil");
    NSAssert(toVersion > 0, @"toVersion must be greater than 0");

    self = [super init];

    if (self)
    {
        self.filepath = filepath;
        self.migrationVersionTarget = toVersion;
    }

    return self;
}

- (NSDictionary *)migratedPackageSettings
{
    if (!_migratedPackageSettings)
    {
        NSError *error;
        self.migratedPackageSettings = [self migrateDictionary:self.packageSettings error:&error];
        self.migrationError = error;
    }

    return _migratedPackageSettings;
}

- (NSDictionary *)packageSettings
{
    if (!_packageSettings)
    {
        self.packageSettings = [NSDictionary dictionaryWithContentsOfFile:_filepath];
    }

    return _packageSettings;
}

- (NSString *)htmlInfoText
{
    return @"Package Settings are of an older version.";
}

- (BOOL)isMigrationRequired
{
    NSDictionary *dict = self.packageSettings;

    // Doing the actual migration, it's not expensive to so the result can be compared to the
    // file's content to see if it changed. Everything else may turn out in alot more code than the needed migration steps.
    NSDictionary *result = self.migratedPackageSettings;

    // If there was an error there's no real way to tell at this point so
    // a migration is required to let a caller run into the actual error with the migrate method
    if (!result)
    {
        return YES;
    }

    return ![dict isEqualToDictionary:result];
}

- (BOOL)migrateWithError:(NSError **)error
{
    if (![self isMigrationRequired])
    {
        return YES;
    }

    if (![self createBackupWithError:error])
    {
        return NO;
    }

    return [self migrate__:error];
}

- (BOOL)migrate__:(NSError **)error
{
    if (self.migratedPackageSettings == nil)
    {
        [NSError setError:error withError:_migrationError];
        return NO;
    }

    NSError *overwriteError;
    if (![self overwritePackageSettings:&overwriteError])
    {
        [NSError setNewErrorWithErrorPointer:error
                                        code:SBMigrationError
                                    userInfo:@{
                                            NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Could not overwrite existing Package Settings with migrated version at \"%@\"", _filepath],
                                            NSUnderlyingErrorKey : overwriteError
                                    }];
        return NO;
    };
    return YES;
}

- (BOOL)overwritePackageSettings:(NSError **)error
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager removeItemAtPath:_filepath error:error])
    {
        return NO;
    }

    if (![self.migratedPackageSettings writeToFile:_filepath atomically:YES])
    {
        [NSError setNewErrorWithErrorPointer:error code:SBMigrationError message:@"Dictionary Write error"];
        return NO;
    }
    return YES;
}

- (BOOL)createBackupWithError:(NSError **)error
{
    self.backupFileCommand = [[BackupFileCommand alloc] initWithFilePath:_filepath];
    NSError *backupError;
    if (![_backupFileCommand execute:&backupError])
    {
        [NSError setNewErrorWithErrorPointer:error code:SBMigrationError userInfo:@{
                NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Could not create backup file of package settings at \"%@\"", _filepath],
                NSUnderlyingErrorKey : backupError
        }];
        return NO;
    };
    return YES;
}

- (void)rollback
{
    [_backupFileCommand undo:nil];
}

- (void)tidyUp
{
    [_backupFileCommand tidyUp];
}

- (NSDictionary *)migrateDictionary:(NSDictionary *)dict error:(NSError **)error
{
    if (!dict || [dict count] == 0)
    {
        [NSError setNewErrorWithErrorPointer:error
                                        code:SBPackageSettingsEmptyOrDoesNotExist
                                     message:[NSString stringWithFormat:@"Dictionary at \"%@\" does not exist or is empty", _filepath]];
        return nil;
    }


    NSUInteger currentVersion = 1;
    if (_packageSettings[@"version"])
    {
        currentVersion = [_packageSettings[@"version"] unsignedIntegerValue];
    }

    if (currentVersion == _migrationVersionTarget)
    {
        return _packageSettings;
    }

    if (_migrationVersionTarget < currentVersion)
    {
        [NSError setNewErrorWithErrorPointer:error
                                        code:SBPackageSettingsMigrationCannotDowngraderError
                                     message:[NSString stringWithFormat:@"Cannot downgrade version %lu to version %lu", currentVersion, _migrationVersionTarget]];
        return nil;
    }

    return [self migrateFromVersion:currentVersion error:error];
}

- (NSDictionary *)migrate:(NSError **)error
{

}

- (NSDictionary *)migrateFromVersion:(NSUInteger)fromVersion error:(NSError **)error
{
    NSMutableDictionary *result = CFBridgingRelease(CFPropertyListCreateDeepCopy(NULL, (__bridge CFPropertyListRef)(_packageSettings), kCFPropertyListMutableContainersAndLeaves));;

    NSUInteger currentVersion = fromVersion;
    while (currentVersion < _migrationVersionTarget)
    {
        currentVersion++;
        result = [self migrate:result toVersion:currentVersion withError:error];
        if (!result)
        {
            return nil;
        }
    }

    return result;
}

- (NSMutableDictionary *)migrate:(NSMutableDictionary *)dict toVersion:(NSUInteger)toVersion withError:(NSError **)error
{
    switch (toVersion)
    {
        case 2: return [self migrateToVersion_2:dict withError:error];
        case 3: return [self migrateToVersion_3:dict withError:error];
        default: break;
    }

    [NSError setNewErrorWithErrorPointer:error code:SBPackageSettingsMigrationNoRuleError message:[NSString stringWithFormat:@"Migration rule not found for version %lu", toVersion]];
    return nil;
};

- (NSMutableDictionary *)migrateToVersion_2:(NSMutableDictionary *)dict withError:(NSError **)error
{
    if (!dict[@"resourceAutoScaleFactor"])
    {
        dict[@"resourceAutoScaleFactor"] = @-1;
    }

    dict[@"version"] = @2;

    return dict;
}

- (NSMutableDictionary *)migrateToVersion_3:(NSMutableDictionary *)dict withError:(NSError **)error
{
    if (!dict[@"resourceAutoScaleFactor"] || [dict[@"resourceAutoScaleFactor"] unsignedIntegerValue] == -1)
    {
        dict[@"resourceAutoScaleFactor"] = @4;
    }

    dict[@"mainProjectResolutions"] = @[ @4 ];

    dict[@"osSettings"][@"ios"][@"resolutions"] = [self migrateOldDeviceTagsToResolutions:dict[@"osSettings"][@"ios"][@"resolutions"]];
    dict[@"osSettings"][@"android"][@"resolutions"] = [self migrateOldDeviceTagsToResolutions:dict[@"osSettings"][@"android"][@"resolutions"]];

    dict[@"version"] = @3;

    return dict;
}

- (NSArray *)migrateOldDeviceTagsToResolutions:(NSDictionary *)deviceTags
{
    NSMutableSet *resolutions = [NSMutableSet set];

    for (NSString *deviceTag in deviceTags)
    {
        if ([deviceTag isEqualToString:@"phone"])
        {
            [resolutions addObject:@1];
        }

        if ([deviceTag isEqualToString:@"phonehd"] || [deviceTag isEqualToString:@"tablet"])
        {
            [resolutions addObject:@2];
        }

        if ([deviceTag isEqualToString:@"tablethd"])
        {
            [resolutions addObject:@4];
        }
    }
    return [resolutions allObjects];
}

@end
