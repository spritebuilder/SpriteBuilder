//
//  TranslationSettings.m
//  SpriteBuilder
//
//  Created by Benjamin Koatz on 7/21/14.
//
//

#import "TranslationSettings.h"
#import "AppDelegate.h"
#import "SequencerJoints.h"


@implementation TranslationSettings

@synthesize projectsDownloadingTranslations = _projectsDownloadingTranslations;

static TranslationSettings *singleton;

/*
 * Creates singleton translation settings
 */
+ (TranslationSettings*) translationSettings
{
    @synchronized([TranslationSettings class])
    {
        if (!singleton)
            singleton = [[self alloc] init];
        else
            [singleton loadTranslationSettings];
        return singleton;
    }
    
    return nil;
}

/*
 * Initializes, loads and then writes the translation settings
 */
- (id)init
{
    self = [super init];
    if (!self) return NULL;
    
    self.projectsDownloadingTranslations = [[[NSUserDefaults standardUserDefaults] objectForKey:@"projectsDownloadingTranslations"] mutableCopy];
    
    if(!self.projectsDownloadingTranslations)
    {
        self.projectsDownloadingTranslations = [[NSMutableArray alloc] init];
        [self writeTranslationSettings];
    }
    
    
    return self;
    
}

/*
 * Writes and loads translation settings
 */
- (void)updateTranslationSettings
{
    [self writeTranslationSettings];
    [self loadTranslationSettings];
}

/*
 * Loads translation settings
 */
- (void)loadTranslationSettings
{
    self.projectsDownloadingTranslations = [[[NSUserDefaults standardUserDefaults] objectForKey:@"projectsDownloadingTranslations"] mutableCopy];
    
    if(!self.projectsDownloadingTranslations)
    {
        self.projectsDownloadingTranslations = [[NSMutableArray alloc] init];
        [self writeTranslationSettings];
    }
}

/*
 * Writes translation settings
 */
- (void) writeTranslationSettings
{
    [[NSUserDefaults standardUserDefaults] setObject:self.projectsDownloadingTranslations forKey:@"projectsDownloadingTranslations"];
}

/*
 * Adds an observer for a keyPath
 */
-(void)addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context{
    
    if(self.observer)
    {
        [self removeObserver:self.observer forKeyPath:keyPath];
    }
    [super addObserver:observer forKeyPath:keyPath options:options context:context];
    self.observer = observer;
}

/*
 * Removes an observer for a keyPath
 */
-(void)removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath{
    
    [super removeObserver:observer forKeyPath:keyPath];
    self.observer = nil;
}


@end
