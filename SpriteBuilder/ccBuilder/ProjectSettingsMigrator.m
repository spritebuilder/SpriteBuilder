#import "ProjectSettingsMigrator.h"
#import "CCRenderer_Private.h"

@interface ProjectSettingsMigrator()

@property (nonatomic, copy) NSDictionary *projectSettings;
@property (nonatomic) NSUInteger migrationVersionTarget;

@end


@implementation ProjectSettingsMigrator

- (instancetype)initWithDictionary:(NSDictionary *)projectSettings toVersion:(NSUInteger)toVersion
{
    self = [super init];

    if (self)
    {
        self.projectSettings = projectSettings;
        self.migrationVersionTarget = toVersion;
    }

    return self;
}

- (NSDictionary *)migrate:(NSError **)error
{
    return nil;

}

@end
