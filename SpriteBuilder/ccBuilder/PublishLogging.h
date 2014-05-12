// Debug option: Some verbosity on the console, 1 to enable 0 to turn off
#define PublishLogging 0

#ifdef DEBUG
	#define LocalLog( s, ... ) NSLog( @"<%@:%d> %@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__,  [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
	#define LocalLog( s, ... )
#endif

#if !PublishLogging
    #undef LocalLog
    #define LocalLog( s, ... )
#endif
