
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  late final Dio _dio;
  static const String _baseUrl = 'http://localhost:3000/api'; // Update for production
  static const _storage = FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';
  
  // Toggle for detailed API logging
  static bool enableDetailedLogging = true;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: Duration(milliseconds: 10000),
      receiveTimeout: Duration(milliseconds: 10000),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Add logging interceptor for development
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
        logPrint: (object) {
          // Use a more prominent prefix for API logs
          print('🌐 API: $object');
        },
      ));
    }

    // Add interceptor for auth token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        
        // Additional request logging in debug mode
        if (kDebugMode && enableDetailedLogging) {
          print('🚀 REQUEST: ${options.method} ${options.baseUrl}${options.path}');
          if (options.data != null) {
            print('📤 REQUEST BODY: ${options.data}');
          }
          if (options.queryParameters.isNotEmpty) {
            print('🔍 QUERY PARAMS: ${options.queryParameters}');
          }
        }
        
        handler.next(options);
      },
      onResponse: (response, handler) async {
        // Custom response logging in debug mode
        if (kDebugMode && enableDetailedLogging) {
          print('✅ RESPONSE: ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.path}');
          print('📥 RESPONSE BODY: ${response.data}');
        }
        handler.next(response);
      },
      onError: (error, handler) async {
        // Enhanced error logging in debug mode
        if (kDebugMode && enableDetailedLogging) {
          print('❌ ERROR: ${error.response?.statusCode} ${error.requestOptions.method} ${error.requestOptions.path}');
          if (error.response?.data != null) {
            print('💥 ERROR BODY: ${error.response?.data}');
          }
          print('🔥 ERROR MESSAGE: ${error.message}');
        }
        
        // Handle token expiration
        if (error.response?.statusCode == 401) {
          await clearToken();
          // Could trigger navigation to login here
        }
        handler.next(error);
      },
    ));
  }

  // Token management
  Future<String?> getToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (e) {
      return null;
    }
  }

  Future<void> setToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // Utility methods for debugging
  static void enableLogging() {
    enableDetailedLogging = true;
    if (kDebugMode) {
      print('🔧 API detailed logging enabled');
    }
  }

  static void disableLogging() {
    enableDetailedLogging = false;
    if (kDebugMode) {
      print('🔧 API detailed logging disabled');
    }
  }

  // Test connectivity
  Future<bool> testConnection() async {
    try {
      final response = await _dio.get('/health');
      if (kDebugMode) {
        print('🏥 Health check successful: ${response.data}');
      }
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('🚨 Health check failed: $e');
      }
      return false;
    }
  }

  // Auth endpoints
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final response = await _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
    });
    
    if (response.data['token'] != null) {
      await setToken(response.data['token']);
    }
    
    return response.data;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    
    if (response.data['token'] != null) {
      await setToken(response.data['token']);
    }
    
    return response.data;
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await _dio.get('/auth/me');
    return response.data;
  }

  Future<Map<String, dynamic>> invitePartner({
    required String email,
    String? message,
  }) async {
    final response = await _dio.post('/auth/invite-partner', data: {
      'email': email,
      'message': message,
    });
    return response.data;
  }

  // User endpoints
  Future<Map<String, dynamic>> getUserProfile() async {
    final response = await _dio.get('/users/profile');
    return response.data;
  }

  Future<Map<String, dynamic>> updateProfile({
    required String firstName,
    required String lastName,
  }) async {
    final response = await _dio.put('/users/profile', data: {
      'firstName': firstName,
      'lastName': lastName,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getInvitations() async {
    final response = await _dio.get('/users/invitations');
    return response.data;
  }

  Future<Map<String, dynamic>> acceptInvitation(String invitationId) async {
    final response = await _dio.post('/users/accept-invitation/$invitationId');
    return response.data;
  }

  // Conversation endpoints
  Future<Map<String, dynamic>> getConversations() async {
    final response = await _dio.get('/conversations');
    return response.data;
  }

  Future<Map<String, dynamic>> createConversation({
    required String title,
    String? topic,
  }) async {
    final response = await _dio.post('/conversations', data: {
      'title': title,
      'topic': topic,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getConversation(String conversationId) async {
    final response = await _dio.get('/conversations/$conversationId');
    return response.data;
  }

  Future<Map<String, dynamic>> updateConversation({
    required String conversationId,
    required String title,
    String? topic,
  }) async {
    final response = await _dio.put('/conversations/$conversationId', data: {
      'title': title,
      'topic': topic,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> deleteConversation(String conversationId) async {
    final response = await _dio.delete('/conversations/$conversationId');
    return response.data;
  }

  // Message endpoints
  Future<Map<String, dynamic>> getMessages(String conversationId, {
    int limit = 50,
    String? lastMessageId,
  }) async {
    final response = await _dio.get('/messages/$conversationId', queryParameters: {
      'limit': limit,
      if (lastMessageId != null) 'lastMessageId': lastMessageId,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    required String content,
    String recipientType = 'both',
  }) async {
    final response = await _dio.post('/messages/$conversationId', data: {
      'content': content,
      'recipientType': recipientType,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> editMessage({
    required String messageId,
    required String content,
  }) async {
    final response = await _dio.put('/messages/$messageId', data: {
      'content': content,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> deleteMessage(String messageId) async {
    final response = await _dio.delete('/messages/$messageId');
    return response.data;
  }

  // Error handling helper
  static ApiException handleError(DioException error) {
    if (error.response != null) {
      final data = error.response!.data;
      return ApiException(
        message: data['message'] ?? 'An error occurred',
        statusCode: error.response!.statusCode,
        error: data['error'],
      );
    }
    
    return ApiException(
      message: 'Network error occurred',
      statusCode: 0,
      error: error.message,
    );
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? error;

  ApiException({
    required this.message,
    this.statusCode,
    this.error,
  });

  @override
  String toString() => message;
}
