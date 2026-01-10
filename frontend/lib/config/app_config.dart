/// Application configuration
class AppConfig {
  // API Base URL
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  // App Information
  static const String appName = 'We Counsel';
  static const String appVersion = '1.0.0';

  // API Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration connectTimeout = Duration(seconds: 10);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Feature Flags
  static const bool enableDebugLogging = true;
  static const bool enableAnalytics = false;
}
