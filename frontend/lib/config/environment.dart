/// Environment configuration for different deployment targets
class Environment {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  static bool get isProduction => environment == 'production';
  static bool get isDevelopment => environment == 'development';

  static void log(String message) {
    if (!isProduction) {
      print(message);
    }
  }

  static void printConfig() {
    if (isProduction) return;

    log('🔧 Environment Configuration:');
    log('   Environment: $environment');
    log('   API Base URL: $apiBaseUrl');
    log('   Is Production: $isProduction');
  }
}
