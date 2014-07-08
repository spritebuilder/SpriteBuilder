// SpriteBuilder error domain
extern NSString *const SBErrorDomain;

// === Error codes ===

// GUI / DragnDrop
extern NSInteger const SBNodeDoesNotSupportChildrenError;
extern NSInteger const SBChildRequiresSpecificParentError;
extern NSInteger const SBParentDoesNotPermitSpecificChildrenError;

// Update Cocos2d
extern NSInteger const SBCocos2dUpdateTemplateZipFileDoesNotExistError;
extern NSInteger const SBCocos2dUpdateUnzipTemplateFailedError;
extern NSInteger const SBCocos2dUpdateUnzipTaskError;

// Resource path / Packages
extern NSInteger const SBDuplicateResourcePathError;
extern NSInteger const SBResourcePathNotInProjectError;
extern NSInteger const SBImportingPackagesError;
extern NSInteger const SBRemovePackagesError;
extern NSInteger const SBResourcePathExistsButNotInProjectError;
extern NSInteger const SBPackageExportInvalidPackageError;
extern NSInteger const SBPackageAlreadyExistsAtPathError;
extern NSInteger const SBRenamePackageGenericError;
extern NSInteger const SBPathWithoutPackageSuffix;
extern NSInteger const SBNoPackagePathsToImport;
extern NSInteger const SBPackageAlreayInProject;