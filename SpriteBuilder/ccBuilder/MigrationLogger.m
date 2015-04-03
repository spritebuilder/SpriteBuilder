#import <AVFoundation/AVFoundation.h>
#import "MigrationLogger.h"


@interface MigrationLogger()

@property (nonatomic, strong) NSMutableArray *logMessages;

@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@end


@implementation MigrationLogger

- (instancetype)initWithLogToConsole:(BOOL)logToConsole
{
    self = [super init];

    if (self)
    {
        self.logMessages = [NSMutableArray array];
        self.logToConsole = logToConsole;
        self.dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";
    }

    return self;
}

- (instancetype)init
{
    return [self initWithLogToConsole:NO];
}

- (void)log:(NSString *)message section:(id)section
{
    if (!section)
    {
        [self log:message];
        return;
    }

    NSString *sectionString;
    if ([section isKindOfClass:[NSArray class]])
    {
        sectionString = [NSString stringWithFormat:@"[%@] ", [section componentsJoinedByString:@"] ["]];
    }
    else if ([section isKindOfClass:[NSString class]])
    {
        sectionString = [NSString stringWithFormat:@"[%@] ", section];
    }
    else
    {
        sectionString = @"";
    }

    [self log:[NSString stringWithFormat:@"%@%@", sectionString, message]];
}

- (void)log:(NSString *)message
{
    NSString *timeStamp = [_dateFormatter stringFromDate:[[NSDate date] init]];

    NSString *fullMessage = [NSString stringWithFormat:@"[%@] %@", timeStamp, message];

    if (_logToConsole)
    {
        NSLog(@"%@", message);
    }

    [_logMessages addObject:fullMessage];
}

- (NSArray *)allLogMessages
{
    return _logMessages;
}

- (NSString *)log
{
    return [_logMessages componentsJoinedByString:@"\n"];
}

@end
