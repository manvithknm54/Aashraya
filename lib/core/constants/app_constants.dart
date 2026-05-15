class AppConstants {
  // App Info
  static const String appName = 'Aashraya';
  static const String appTagline = 'Care. Connect. Comfort.';
  static const String appVersion = '1.0.0';

  // User Roles
  static const String roleElder = 'elder';
  static const String roleCaretaker = 'caretaker';

  // Shared Prefs Keys
  static const String keyUserRole = 'user_role';
  static const String keyUserId = 'user_id';
  static const String keyOnboarded = 'is_onboarded';
  static const String keyThemeMode = 'theme_mode';

  // Firestore Collections
  static const String colUsers = 'users';
  static const String colTasks = 'tasks';
  static const String colReports = 'reports';
  static const String colMedicines = 'medicines';
  static const String colSosAlerts = 'sos_alerts';
  static const String colMessages = 'messages';

  // Task Categories
  static const List<String> taskCategories = [
    'Medicine', 'Exercise', 'Water', 'Walk', 'Food', 'Sleep', 'Other'
  ];

  // Task Icons (mapped to categories)
  static const Map<String, String> taskIcons = {
    'Medicine': '💊',
    'Exercise': '🏃',
    'Water': '💧',
    'Walk': '🚶',
    'Food': '🍽️',
    'Sleep': '😴',
    'Other': '📋',
  };
}