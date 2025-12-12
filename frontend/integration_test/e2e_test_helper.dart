import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// E2E Test Helper
/// Provides utilities for testing with mock backend
class E2ETestHelper {
  final String apiUrl;
  
  E2ETestHelper(this.apiUrl);
  
  /// Reset all mock stores
  Future<void> resetMocks() async {
    final response = await http.post(Uri.parse('$apiUrl/api/test/reset'));
    expect(response.statusCode, 200);
  }
  
  /// Get all mock emails sent
  Future<List<dynamic>> getMockEmails() async {
    final response = await http.get(Uri.parse('$apiUrl/api/test/emails'));
    expect(response.statusCode, 200);
    final data = jsonDecode(response.body);
    return data['emails'] as List;
  }
  
  /// Get mock emails by type
  Future<List<dynamic>> getMockEmailsByType(String type) async {
    final response = await http.get(Uri.parse('$apiUrl/api/test/emails/$type'));
    expect(response.statusCode, 200);
    final data = jsonDecode(response.body);
    return data['emails'] as List;
  }
  
  /// Get all mock AI responses
  Future<List<dynamic>> getMockAIResponses() async {
    final response = await http.get(Uri.parse('$apiUrl/api/test/ai-responses'));
    expect(response.statusCode, 200);
    final data = jsonDecode(response.body);
    return data['responses'] as List;
  }
  
  /// Verify test environment status
  Future<Map<String, dynamic>> getTestStatus() async {
    final response = await http.get(Uri.parse('$apiUrl/api/test/status'));
    expect(response.statusCode, 200);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
  
  /// Find email by recipient
  Future<Map<String, dynamic>?> findEmailByRecipient(String email) async {
    final emails = await getMockEmails();
    for (final emailData in emails) {
      if (emailData['to'] == email) {
        return emailData as Map<String, dynamic>;
      }
    }
    return null;
  }
  
  /// Wait for email to be sent (with timeout)
  Future<Map<String, dynamic>> waitForEmail({
    required String to,
    String? type,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final startTime = DateTime.now();
    
    while (DateTime.now().difference(startTime) < timeout) {
      final emails = type != null 
          ? await getMockEmailsByType(type)
          : await getMockEmails();
      
      for (final email in emails) {
        if (email['to'] == to) {
          return email as Map<String, dynamic>;
        }
      }
      
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    throw TimeoutException('Email to $to not found within ${timeout.inSeconds}s');
  }
  
  /// Wait for AI response (with timeout)
  Future<Map<String, dynamic>> waitForAIResponse({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final startTime = DateTime.now();
    
    while (DateTime.now().difference(startTime) < timeout) {
      final responses = await getMockAIResponses();
      
      if (responses.isNotEmpty) {
        return responses.last as Map<String, dynamic>;
      }
      
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    throw TimeoutException('AI response not found within ${timeout.inSeconds}s');
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  
  @override
  String toString() => 'TimeoutException: $message';
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  // Get API URL from dart-define
  const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:3001');
  late E2ETestHelper testHelper;
  
  setUpAll(() {
    testHelper = E2ETestHelper(apiUrl);
  });
  
  setUp(() async {
    // Reset mocks before each test
    await testHelper.resetMocks();
  });

  group('E2E Test Examples', () {
    testWidgets('Test environment is properly configured', (WidgetTester tester) async {
      final status = await testHelper.getTestStatus();
      
      expect(status['success'], true);
      expect(status['environment']['mockEmail'], true);
      expect(status['environment']['mockAI'], true);
      expect(status['environment']['dynamodbEndpoint'], contains('localhost'));
    });
    
    testWidgets('Mock email service works', (WidgetTester tester) async {
      // Initially no emails
      final initialEmails = await testHelper.getMockEmails();
      expect(initialEmails, isEmpty);
      
      // TODO: Trigger an action that sends an email
      // For now, this is just a placeholder test
      
      // Example assertion (when you implement the action):
      // final email = await testHelper.waitForEmail(to: 'test@example.com');
      // expect(email['type'], 'invitation');
    });
    
    testWidgets('Mock AI service works', (WidgetTester tester) async {
      // Initially no AI responses
      final initialResponses = await testHelper.getMockAIResponses();
      expect(initialResponses, isEmpty);
      
      // TODO: Trigger an action that generates AI response
      // For now, this is just a placeholder test
      
      // Example assertion (when you implement the action):
      // final aiResponse = await testHelper.waitForAIResponse();
      // expect(aiResponse['response'], isNotEmpty);
    });
  });
}
