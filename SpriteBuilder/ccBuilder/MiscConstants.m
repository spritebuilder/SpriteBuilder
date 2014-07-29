#ifdef SPRITEBUILDER_PRO
BOOL const IS_SPRITEBUILDER_PRO = YES;
#else
BOOL const IS_SPRITEBUILDER_PRO = NO;
#endif

NSInteger const DEFAULT_AUDIO_QUALITY = 4;

NSString *const PACKAGE_NAME_SUFFIX = @"sbpack";

NSString *const PACKAGES_FOLDER_NAME = @"Packages";

NSString *const INTERMEDIATE_FILE_LOOKUP_NAME = @"intermediateFileLookup.plist";

NSString *const PUBLISHER_CACHE_DIRECTORY_NAME = @"com.cocosbuilder.CocosBuilder";

NSUInteger const PUBLISHING_PACKAGES_ZIP_DEBUG_COMPRESSION = 0;
NSUInteger const PUBLISHING_PACKAGES_ZIP_RELEASE_COMPRESSION = 9;

NSString *const DEFAULT_OUTPUTDIR_PUBLISHED_PACKAGES = @"Published-Packages";

NSString *const PACKAGE_PUBLISH_SETTINGS_FILE_NAME = @"Package.plist";