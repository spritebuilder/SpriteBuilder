//
//  NSDictionary+SMKeyValueObserving.h
//  InspectorTabBar
//
//  Created by Stephan Michels on 04.02.12.
//  Copyright (c) 2012 Stephan Michels Softwareentwicklung und Beratung. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSDictionary (SMKeyValueObserving)

@property (readonly) NSUInteger keyValueChangeKind;
@property (readonly) id keyValueChangeNew;
@property (readonly) id keyValueChangeOld;
@property (readonly) NSIndexSet *keyValueChangeIndexes;
@property (readonly) BOOL keyValueChanged;

@end
