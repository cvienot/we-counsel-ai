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

  static void printConfig() {
    print('🔧 Environment Configuration:');
    print('   Environment: $environment');
    print('   API Base URL: $apiBaseUrl');
    print('   Is Production: $isProduction');
  }
}
