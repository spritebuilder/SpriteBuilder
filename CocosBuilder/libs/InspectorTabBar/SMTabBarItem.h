//
//  SMTabBarItem.h
//  InspectorTabBar
//
//  Created by Stephan Michels on 03.02.12.
//  Copyright (c) 2012 Stephan Michels Softwareentwicklung und Beratung. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SMTabBarItem : NSObject

@property (nonatomic) BOOL enabled;
@property (nonatomic, strong) NSImage *image;
@property (nonatomic, copy) NSString *toolTip;
@property (nonatomic, copy) NSString *keyEquivalent;
@property (nonatomic) NSUInteger keyEquivalentModifierMask;
@property (nonatomic) NSInteger tag;

- (id)initWithImage:(NSImage *)image tag:(NSInteger)tag;

@end
