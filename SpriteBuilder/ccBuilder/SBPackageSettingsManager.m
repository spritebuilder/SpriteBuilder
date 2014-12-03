#import "SBPackageSettingsManager.h"
#import "SBPackageSettings.h"
#import "RMPackage.h"
#import "ResourceManager.h"
#import "NotificationNames.h"

@interface SBPackageSettingsManager ()

@property (nonatomic, strong) NSMutableArray *packageSettings;

@end


@implementation SBPackageSettingsManager

+ (SBPackageSettingsManager *)sharedManager
{
    static SBPackageSettingsManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        sharedInstance = [[SBPackageSettingsManager alloc] init];
    });
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        self.packageSettings = [NSMutableArray array];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resourceRemoved:) name:RESOURCE_REMOVED object:nil];
    }

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)resourceRemoved:(NSNotification *)notification
{
    if (![notification.object isKindOfClass:[RMPackage class]])
    {
        return;
    }

    SBPackageSettings *packageSettings = [self packageSettingsForPackage:notification.object];
    [self removePackageSettings:packageSettings];
}

- (NSArray *)allPackageSettings
{
    return _packageSettings;
}

- (SBPackageSettings *)packageSettingsForPackage:(RMPackage *)package
{
    for (SBPackageSettings *packageSettings in _packageSettings)
    {
        if (packageSettings.package == package)
        {
            return packageSettings;
        }
    }

    return nil;
}

- (SBPackageSettings *)createPackageSettingsWithPackage:(RMPackage *)package
{
    NSAssert(package != nil, @"package must not be nil");

    SBPackageSettings *packagePublishSettings = [[SBPackageSettings alloc] initWithPackage:package];
    [packagePublishSettings store];

    [self addPackageSettings:packagePublishSettings];

    return packagePublishSettings;
}

- (void)addPackageSettings:(SBPackageSettings *)packageSettings
{
    NSAssert(packageSettings != nil, @"packageSettings must not be nil");

    if ([self packageSettingsForPackage:packageSettings.package])
    {
        return;
    }

    [_packageSettings addObject:packageSettings];
}

- (void)removePackageSettings:(SBPackageSettings *)packageSettings
{
    [_packageSettings removeObject:packageSettings];
}

- (void)loadAllPackageSettings
{
    NSArray *allPackages = [_resourceManager allPackages];
    [self saveAllPackageSettings];
    [_packageSettings removeAllObjects];

    for (RMPackage *aPackage in allPackages)
    {
        SBPackageSettings *packagePublishSettings = [[SBPackageSettings alloc] initWithPackage:aPackage];
        [packagePublishSettings load];

        [self addPackageSettings:packagePublishSettings];
    }
}

- (void)saveAllPackageSettings
{
    for (SBPackageSettings *packageSettings in _packageSettings)
    {
        [packageSettings store];
    }
}

@end
