#import "CCBDictionaryMigrator.h"
#import "CCBReader_Private.h"
#import "CCBDictionaryReader.h"
#import "CCBDictionaryMigrationProtocol.h"
#import "CCBDictionaryKeys.h"
#import "NSString+Misc.h"
#import "NSError+SBErrors.h"
#import "Errors.h"


@interface CCBDictionaryMigrator()

@property (nonatomic, readwrite) NSDictionary *ccb;
@property (nonatomic) NSUInteger ccbMigrationVersionTarget;

@end


@implementation CCBDictionaryMigrator

- (instancetype)initWithCCB:(NSDictionary *)ccb toVersion:(NSUInteger)toVersion
{
    NSAssert(ccb != nil, @"ccb must not be nil");
    NSAssert(toVersion > 0, @"toVersion must greater than 0");

    self = [super init];
    if (self)
    {
        self.ccb = ccb;
        self.migrationStepClassPrefix = @"CCBDictionaryMigrationStepVersion";
        self.ccbMigrationVersionTarget = toVersion;
    }

    return self;
}

- (NSDictionary *)migrate:(NSError **)error
{
    if (!_migrationStepClassPrefix || [_migrationStepClassPrefix isEmpty])
    {
        [NSError setNewErrorWithErrorPointer:error code:SBCCBMigrationNoMigrationStepClassPrefixError message:@"Class prefix for migration step classes is empty or nil"];
        return nil;
    }

    if (!_ccb[CCB_DICTIONARY_KEY_FILEVERSION])
    {
        [NSError setNewErrorWithErrorPointer:error code:SBCCBMigrationNoVersionFoundError message:@"Could not determine ccb's version"];
        return nil;
    }

    int fileVersion = [_ccb[CCB_DICTIONARY_KEY_FILEVERSION] intValue];

    if (fileVersion >= _ccbMigrationVersionTarget)
    {
        return _ccb;
    }

    NSDictionary *migratedCCB = _ccb;

    int currentVersionPass = fileVersion;
    while(currentVersionPass < _ccbMigrationVersionTarget)
    {
        Class migrationStepClass = NSClassFromString([NSString stringWithFormat:@"%@%d", _migrationStepClassPrefix, currentVersionPass]);

        currentVersionPass++;

        if (!migrationStepClass)
        {
            continue;
        }

        id migrationStep = (id) [[migrationStepClass alloc] init];
        if (![migrationStep conformsToProtocol:@protocol(CCBDictionaryMigrationProtocol)])
        {
            continue;
        }

        NSError *underylingError;
        migratedCCB = [migrationStep migrate:migratedCCB error:&underylingError];

        if (!migratedCCB)
        {
            [NSError setNewErrorWithErrorPointer:error
                                            code:SBCCBMigrationError
                                        userInfo:@{
                                                NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Migration failed for version %d. See NSUnderlyingErrorKey for details.", currentVersionPass],
                                                NSUnderlyingErrorKey : underylingError
                                        }];
            return nil;
        };
    }

    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithDictionary:migratedCCB];

    result[CCB_DICTIONARY_KEY_FILEVERSION] = @(_ccbMigrationVersionTarget);

    return result;
}

@end
