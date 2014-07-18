@class CCBDirectoryPublisher;
@class ProjectSettings;
@class CCBWarnings;

typedef void (^PublisherFinishBlock)(CCBDirectoryPublisher *publisher, CCBWarnings *warnings);

enum {
    kCCBPublishFormatSound_ios_caf = 0,
    kCCBPublishFormatSound_ios_mp4 = 1,
} typedef kCCBPublishFormatSound_ios;

enum {
    kCCBPublishFormatSound_android_ogg = 0,
} typedef kCCBPublishFormatSound_android;
