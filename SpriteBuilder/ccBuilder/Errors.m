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
NSInteger const SBCocos2dUpdateCopyFilesError = 2003;
NSInteger const SBCocos2dUpdateUserCancelledError = 2010;

// Resource path / Packages
NSInteger const SBDuplicatePackageError = 2100;
NSInteger const SBPackageNotInProjectError = 2101;
NSInteger const SBImportingPackagesError = 2102;
NSInteger const SBPackageExistsButNotInProjectError = 2103;
NSInteger const SBRemovePackagesError = 2104;
NSInteger const SBPackageExportInvalidPackageError = 2105;
NSInteger const SBPackageAlreadyExistsAtPathError = 2106;
NSInteger const SBRenamePackageGenericError = 2107;
NSInteger const SBPathWithoutPackageSuffix = 2108;
NSInteger const SBNoPackagePathsToImport = 2109;
NSInteger const SBPackageAlreayInProject = 2110;
NSInteger const SBEmptyPackageNameError = 2111;

NSInteger const SBMigrationError = 2200;
NSInteger const SBMigrationCannotDowngradeError = 2201;

// CCB Reading and writing
NSInteger const SBCCBReadingError = 3000;
NSInteger const SBCCBReadingErrorInvalidFileType = 3001;
NSInteger const SBCCBReadingErrorVersionTooOld = 3002;
NSInteger const SBCCBReadingErrorVersionHigherThanSpritebuilderSupport = 3003;
NSInteger const SBCCBReadingErrorNoNodesFound = 3004;

NSInteger const SBCCBMigrationError = 3010;
NSInteger const SBCCBMigrationCancelledError = 3011;
NSInteger const SBCCBMigrationNoMigrationStepClassPrefixError = 3012;
NSInteger const SBCCBMigrationNoVersionFoundError = 3013;

NSInteger const SBPackageSettingsMigrationNoRuleError = 3100;
NSInteger const SBPackageSettingsEmptyOrDoesNotExist = 3102;

NSInteger const SBProjectMigrationError = 3200;

NSInteger const SBFileCommandBackupError = 3300;
NSInteger const SBFileCommandBackupAlreadyExecutedError = 3301;
NSInteger const SBFileCommandBackupAlreadyUndoneError = 3302;
NSInteger const SBFileCommandBackupCannotUndoNonExecutedCommandError = 3303;