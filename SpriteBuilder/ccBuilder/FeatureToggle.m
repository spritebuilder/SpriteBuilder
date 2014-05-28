//
//  FeatureToggle.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 28.05.14.
//
//

#import "FeatureToggle.h"

#import <objc/runtime.h>


@interface FeatureToggle ()

@end


@implementation FeatureToggle

static FeatureToggle *sharedFeatures;
static dispatch_once_t onceToken;

+ (instancetype)sharedFeatures
{
    dispatch_once(&onceToken, ^
    {
        sharedFeatures = [[self alloc] init];
    });

    return sharedFeatures;
}

- (void)loadFeatureJsonConfigFromBundleWithFileName:(NSString *)fileName
{
    NSString *configPath = [[NSBundle mainBundle] pathForResource:fileName ofType:nil];

    if (!configPath)
    {
        NSLog(@"[FEATURETOGGLE] ERROR file does not exist: %@", fileName);
        return;
    }

    NSError *errorConfigLoading;
    NSData *configContents = [NSData dataWithContentsOfFile:configPath
                                                    options:NSDataReadingUncached
                                                      error:&errorConfigLoading];

    if (!configContents)
    {
        NSLog(@"[FEATURETOGGLE] ERROR reading feature config file: %@", errorConfigLoading);
        return;
    }

    [self loadFeaturesWithJsonData:configContents];
}

- (void)loadFeaturesWithJsonData:(NSData *)data
{
    if(!data)
    {
        return;
    }

    NSError *errorJsonParsing;
    NSMutableDictionary *objectGraph = [NSJSONSerialization JSONObjectWithData:data
                                                                       options:NSJSONReadingMutableContainers
                                                                         error:&errorJsonParsing];

    if (!objectGraph)
    {
        NSLog(@"[FEATURETOGGLE] ERROR reading feature config file: %@", errorJsonParsing);
        return;
    }

    [self setPropertiesWithFeatures:objectGraph];
}

- (void)setPropertiesWithFeatures:(NSDictionary *)features
{
    for (NSString *key in features)
    {
        if ([self isPropertyKeySettable:key onInstance:self])
        {
            [self setValue:[features objectForKey:key] forKey:key];
            NSLog(@"[FEATURETOGGLE] feature loaded: %@:%@", key, [features objectForKey:key]);
        }
    }
}

- (BOOL)isPropertyKeySettable:(NSString *)key onInstance:(id)instance
{
    if (!key || !instance || ([key length] == 0))
    {
        return NO;
    }

    NSString *firstCharacterOfKey = [[key substringWithRange:NSMakeRange(0, 1)] uppercaseString];
    NSString *uppercaseKey = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:firstCharacterOfKey];
    NSString *setterName = [NSString stringWithFormat:@"set%@", uppercaseKey];

    if ([instance respondsToSelector:NSSelectorFromString(setterName)])
    {
        return YES;
    }

    NSArray *setOfDirectlySettableIvarNames = @[[NSString stringWithFormat:@"_%@", key],
                                                [NSString stringWithFormat:@"_is%@", uppercaseKey],
                                                key,
                                                [NSString stringWithFormat:@"is%@", uppercaseKey]];

    return [self doesIvarNameExistInClassHierarchy:[instance class] searchForIvarNames:setOfDirectlySettableIvarNames];
}

- (BOOL)doesIvarNameExistInClassHierarchy:(Class)class searchForIvarNames:(NSArray *)searchedIvarNames
{
    if ([class accessInstanceVariablesDirectly])
    {
        NSArray *ivarNames = [self getIvarNamesOfClass:class];

        for (NSString *ivarName in ivarNames)
        {
            if ([searchedIvarNames containsObject:ivarName])
            {
                return YES;
            }
        }
    }

    Class superClass = class_getSuperclass(class);
    if (superClass)
    {
        return [self doesIvarNameExistInClassHierarchy:superClass searchForIvarNames:searchedIvarNames];
    }

    return NO;
}

- (NSArray *)getIvarNamesOfClass:(Class)class
{
    NSMutableArray *result = [NSMutableArray array];
    unsigned int iVarCount;

    Ivar *vars = class_copyIvarList(class, &iVarCount);
    for (int i = 0; i < iVarCount; i++)
    {
        Ivar var = vars[i];
        NSString *ivarName = [NSString stringWithCString:ivar_getName(var) encoding:NSUTF8StringEncoding];
        [result addObject:ivarName];
    }
    free(vars);

    return result;
}

@end
