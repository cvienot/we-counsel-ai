import '../config/environment.dart';

class Constants {
  // API Configuration - uses environment configuration
  static String get apiBaseUrl => Environment.apiBaseUrl;
  
  // WebSocket/SSE Configuration - derive from API base URL
  static String get wsBaseUrl {
    final apiUrl = Environment.apiBaseUrl;
    if (apiUrl.startsWith('https://')) {
      return apiUrl.replaceFirst('https://', 'wss://').replaceFirst('/api', '');
    } else if (apiUrl.startsWith('http://')) {
      return apiUrl.replaceFirst('http://', 'ws://').replaceFirst('/api', '');
    }
    return 'ws://localhost:3000';
  }
  
  // App Configuration
  static const String appName = 'We Coach';
  static const String appVersion = '1.0.0';
  
  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
  
  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration sseReconnectDelay = Duration(seconds: 2);
  static const int maxReconnectAttempts = 5;
  
  // UI Constants
  static const Duration typingIndicatorDelay = Duration(seconds: 3);
  static const Duration messageAnimationDuration = Duration(milliseconds: 300);
}
