//
// Created by Nicky Weber on 23.02.15.
//

#import <Foundation/Foundation.h>

@interface MigrationLogger : NSObject

@property (nonatomic) BOOL logToConsole;

- (instancetype)initWithLogToConsole:(BOOL)logToConsole;

- (void)log:(NSString *)message;

- (void)log:(NSString *)message section:(id)section;

- (NSString *)log;

@end