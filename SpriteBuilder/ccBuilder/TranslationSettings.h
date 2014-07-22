//
//  TranslationSettings.h
//  SpriteBuilder
//
//  Created by Benjamin Koatz on 7/21/14.
//
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "CocosScene.h"
#import "SequencerJoints.h"

@class AppDelegate;

@interface TranslationSettings : NSObject
{
    NSMutableArray *_projectsDownloadingTranslations;
}

// Settings
@property (nonatomic,strong) NSMutableArray *projectsDownloadingTranslations;
@property (nonatomic,strong) NSObject* observer;

+ (TranslationSettings*) translationSettings;

- (void)loadTranslationSettings;
- (void) writeTranslationSettings;
- (void)updateTranslationSettings;

@end
