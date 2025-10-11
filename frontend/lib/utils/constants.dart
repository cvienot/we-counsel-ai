class Constants {
  // API Configuration
  static const String apiBaseUrl = 'http://localhost:3000/api';
  
  // WebSocket/SSE Configuration
  static const String wsBaseUrl = 'ws://localhost:3000';
  
  // App Configuration
  static const String appName = 'We Counsel';
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
