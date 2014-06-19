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

- (void)loadFeaturesWithDictionary:(NSDictionary *)dict
{
    if(!dict)
    {
        return;
    }

    for (NSString *key in dict)
    {
        if ([self isPropertyKeySettable:key onInstance:self])
        {
            [self setValue:[dict objectForKey:key] forKey:key];
            BOOL isEnabled = [[dict objectForKey:key] boolValue];
            if (isEnabled)
            {
                NSLog(@"[FEATURETOGGLE] Feature enabled: %@", key);
            }
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
