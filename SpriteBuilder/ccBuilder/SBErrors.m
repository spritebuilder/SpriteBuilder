// SpriteBuilder error domain
NSString *const SBErrorDomain = @"SBErrorDomain";

// === Error codes ===

// GUI / DragnDrop
NSInteger const SBNodeDoesNotSupportChildrenError = 1000;
NSInteger const SBChildRequiresSpecificParentError = 1001;
NSInteger const SBParentDoesNotPermitSpecificChildrenError = 1002;

// Update Cocos2d
NSInteger const SBCocos2dUpdateTemplateZipFileDoesNotExistError = 2000;
NSInteger const SBCocos2dUpdateUnzipTemplateFailedError = 2001;
NSInteger const SBCocos2dUpdateUnzipTaskError = 2002;

// Resource path / Packages
NSInteger const SBDuplicateResourcePathError = 2100;
NSInteger const SBResourcePathNotInProjectError = 2101;
NSInteger const SBImportingPackagesError = 2102;
NSInteger const SBResourcePathExistsButNotInProjectError = 2103;
NSInteger const SBRemovePackagesError = 2104;
NSInteger const SBPackageExportInvalidPackageError = 2105;
NSInteger const SBPackageAlreadyExistsAtPathError = 2106;
NSInteger const SBRenamePackageGenericError = 2107;
NSInteger const SBPathWithoutPackageSuffix = 2108;
NSInteger const SBNoPackagePathsToImport = 2109;
NSInteger const SBPackageAlreayInProject = 2110;