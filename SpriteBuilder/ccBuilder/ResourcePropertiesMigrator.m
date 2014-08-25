#import <MacTypes.h>
#import "ResourcePropertiesMigrator.h"
#import "ProjectSettings.h"
#import "PackageMigrator.h"


@interface ResourcePropertiesMigrator ()

@property (nonatomic, strong) ProjectSettings *projectSettings;

@end


@implementation ResourcePropertiesMigrator

- (instancetype)initWithProjectSettings:(ProjectSettings *)projectSettings
{
    NSAssert(projectSettings != nil, @"ProjectSettings must be set");

    self = [super init];
    if (self)
    {
        self.projectSettings = projectSettings;
    }

    return self;
}

- (BOOL)migrate
{
    [self migrateResourcePropertyKeepSpritesUntrimmedToTrimSprites];

    return YES;
}

// Note: To refactor the whole setValue redundancies the convention to name the properties the
// same as in the project settings is necessary to prevent special case mapping code.
- (void)migrateResourcePropertyKeepSpritesUntrimmedToTrimSprites
{
    for (NSString *relativePath in [_projectSettings allResourcesRelativePaths])
    {
        [self migrateTrimSpritesPropertyOfSpriteSheetsForRelPath:relativePath];
    }

    [_projectSettings store];
}

- (void)migrateTrimSpritesPropertyOfSpriteSheetsForRelPath:(NSString *)relPath
{
    BOOL dirtyMarked = [_projectSettings isDirtyRelPath:relPath];
    if (![[_projectSettings propertyForRelPath:relPath andKey:@"isSmartSpriteSheet"] boolValue])
    {
        return;
    }

    if ([[_projectSettings propertyForRelPath:relPath andKey:@"keepSpritesUntrimmed"] boolValue])
    {
        [_projectSettings removePropertyForRelPath:relPath andKey:@"keepSpritesUntrimmed"];
    }
    else
    {
        [_projectSettings setProperty:@YES forRelPath:relPath andKey:@"trimSprites"];
    }

    if (!dirtyMarked)
    {
        [_projectSettings clearDirtyMarkerOfRelPath:relPath];
    }
}

@end