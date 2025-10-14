class AppConstants {
  // App Information
  static const String appName = 'BillEase Pro';
  static const String appVersion = '1.0.0';
  
  // Database
  static const String dbName = 'billease_pro.db';
  static const int dbVersion = 1;
  
  // Shared Preferences Keys
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyUserId = 'user_id';
  static const String keyUserName = 'user_name';
  static const String keyBusinessName = 'business_name';
  static const String keyBusinessType = 'business_type';
  static const String keyAutoBackupEnabled = 'auto_backup_enabled';
  static const String keyLastBackupTime = 'last_backup_time';
  
  // Business Types
  static const String businessTypeWholesale = 'wholesale';
  static const String businessTypeRetail = 'retail';
  static const String businessTypeBoth = 'both';
  
  // Bill Types
  static const String billTypeQuickSale = 'quick_sale';
  static const String billTypeWholesale = 'wholesale';
  static const String billTypeRetail = 'retail';
  
  // Bill Status
  static const String billStatusPaid = 'paid';
  static const String billStatusPartiallyPaid = 'partially_paid';
  static const String billStatusDue = 'due';
  static const String billStatusDraft = 'draft';
  
  // Default Batch Names
  static const String batchOld = 'Old';
  static const String batchNew = 'New';
  
  // Default Alert Settings
  static const int defaultLowStockAlertQuantity = 10;
  static const int defaultExpiryAlertDays = 30;
  
  // Date Formats
  static const String dateFormatDisplay = 'dd/MM/yyyy';
  static const String dateTimeFormatDisplay = 'dd/MM/yyyy HH:mm';
  
  // File Export Paths
  static const String exportDirectoryName = 'BillEasePro';
  static const String backupDirectoryName = 'Backups';
  
  // Auto Backup Interval (in hours)
  static const int autoBackupIntervalHours = 12;
}