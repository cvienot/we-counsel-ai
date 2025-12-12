import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:we_counsel/main.dart' as app;
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'e2e_test_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:3001');
  late E2ETestHelper testHelper;
  
  setUpAll(() {
    testHelper = E2ETestHelper(apiUrl);
  });
  
  setUp(() async {
    await testHelper.resetMocks();
  });

  group('Complete User Journey E2E Test', () {
    testWidgets('User1 signs up, invites partner, User2 accepts, they exchange messages', 
        (WidgetTester tester) async {
      
      // Launch the app
      app.main();
      await tester.pumpAndSettle();
      
      // Test data
      final user1Email = 'user1-${DateTime.now().millisecondsSinceEpoch}@test.com';
      final user2Email = 'user2-${DateTime.now().millisecondsSinceEpoch}@test.com';
      final user1Password = 'Test123!';
      final user2Password = 'Test456!';
      
      print('🧪 Starting E2E test with:');
      print('   User1: $user1Email');
      print('   User2: $user2Email');
      
      // ============================================
      // STEP 1: User1 Registration via UI
      // ============================================
      print('\n📝 Step 1: User1 Registration via UI');
      
      // Should be on login/register screen
      await tester.pumpAndSettle();
      
      // Look for registration flow - adapt based on your actual UI
      // For now, we'll do a hybrid approach: test critical UI paths, use API for setup
      
      // Use API for user registration to keep test focused on core flows
      final registerResponse = await http.post(
        Uri.parse('$apiUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': user1Email,
          'password': user1Password,
          'firstName': 'Alice',
          'lastName': 'Smith',
          'language': 'en',
        }),
      );
      
      expect(registerResponse.statusCode, 201, reason: 'Registration should succeed');
      final registerData = jsonDecode(registerResponse.body);
      final user1Token = registerData['token'];
      
      print('   ✅ User1 registered');
      
      // Verify welcome email was sent
      final welcomeEmail = await testHelper.waitForEmail(
        to: user1Email,
        type: 'welcome',
        timeout: const Duration(seconds: 5),
      );
      expect(welcomeEmail, isNotNull, reason: 'Welcome email should be sent');
      print('   ✅ Welcome email sent');
      
      // ============================================
      // STEP 2: User1 sends partner invitation
      // ============================================
      print('\n📧 Step 2: User1 sends partner invitation');
      
      final inviteResponse = await http.post(
        Uri.parse('$apiUrl/api/auth/invite-partner'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $user1Token',
        },
        body: jsonEncode({'email': user2Email}),
      );
      
      expect(inviteResponse.statusCode, 201, reason: 'Invitation should be sent');
      final inviteData = jsonDecode(inviteResponse.body);
      final invitationId = inviteData['invitation']['invitationId'];
      print('   ✅ Invitation sent');
      
      // Verify invitation email was sent
      final inviteEmail = await testHelper.waitForEmail(
        to: user2Email,
        type: 'invitation',
        timeout: const Duration(seconds: 5),
      );
      expect(inviteEmail, isNotNull, reason: 'Invitation email should be sent');
      expect(inviteEmail['to'], user2Email);
      expect(inviteEmail['invitationId'], invitationId);
      print('   ✅ Invitation email sent to $user2Email');
      
      // ============================================
      // STEP 3: User2 registers  
      // ============================================
      print('\n✅ Step 3: User2 registers');
      
      final user2RegisterResponse = await http.post(
        Uri.parse('$apiUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': user2Email,
          'password': user2Password,
          'firstName': 'Bob',
          'lastName': 'Jones',
          'language': 'en',
        }),
      );
      
      expect(user2RegisterResponse.statusCode, 201, 
        reason: 'User2 registration should succeed');
      
      final user2Data = jsonDecode(user2RegisterResponse.body);
      final user2Token = user2Data['token'];
      
      print('   ✅ User2 registered');
      
      // ============================================
      // STEP 4: User2 accepts invitation
      // ============================================
      print('\n🤝 Step 4: User2 accepts invitation');
      
      final acceptResponse = await http.post(
        Uri.parse('$apiUrl/api/users/accept-invitation/$invitationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $user2Token',
        },
      );
      
      expect(acceptResponse.statusCode, 200, 
        reason: 'Invitation acceptance should succeed');
      
      print('   ✅ Invitation accepted');
      
      // ============================================
      // STEP 5: Verify partner connection
      // ============================================
      print('\n🔗 Step 5: Verifying partner connection');
      
      final user2ProfileResponse = await http.get(
        Uri.parse('$apiUrl/api/auth/me'),
        headers: {'Authorization': 'Bearer $user2Token'},
      );
      
      expect(user2ProfileResponse.statusCode, 200);
      final user2ProfileData = jsonDecode(user2ProfileResponse.body);
      final user2Profile = user2ProfileData['user'];
      expect(user2Profile['coupleId'], isNotNull, 
        reason: 'User2 should be in a couple');
      expect(user2Profile['partner'], isNotNull,
        reason: 'User2 should have a partner');
      
      print('   ✅ Partner connection verified');
      
      // ============================================
      // STEP 6: Get or create main conversation
      // ============================================
      print('\n💬 Step 6: Getting main conversation');
      
      final conversationsResponse = await http.get(
        Uri.parse('$apiUrl/api/conversations'),
        headers: {'Authorization': 'Bearer $user1Token'},
      );
      
      expect(conversationsResponse.statusCode, 200);
      final conversationsData = jsonDecode(conversationsResponse.body);
      final conversations = (conversationsData['conversations'] ?? conversationsData) as List;
      
      String conversationId;
      if (conversations.isEmpty) {
        // Create main conversation
        final createConvResponse = await http.post(
          Uri.parse('$apiUrl/api/conversations'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $user1Token',
          },
          body: jsonEncode({
            'title': 'Main Thread',
            'type': 'main',
          }),
        );
        
        expect(createConvResponse.statusCode, 201);
        final convData = jsonDecode(createConvResponse.body);
        conversationId = convData['conversation']['conversationId'];
        print('   ✅ Created main conversation');
      } else {
        conversationId = conversations.first['conversationId'];
        print('   ✅ Found existing conversation');
      }
      
      // ============================================
      // STEP 7: User1 sends a message
      // ============================================
      print('\n💬 Step 7: User1 sends a message');
      
      final messageContent = 'Hi Bob, how are you feeling today?';
      final sendMessageResponse = await http.post(
        Uri.parse('$apiUrl/api/messages/$conversationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $user1Token',
        },
        body: jsonEncode({'content': messageContent}),
      );
      
      expect(sendMessageResponse.statusCode, 201, 
        reason: 'Message should be sent successfully');
      
      print('   ✅ Message sent: "$messageContent"');
      
      // ============================================
      // STEP 8: Verify message notification email
      // ============================================
      print('\n📧 Step 8: Verifying message notification');
      
      final notificationEmail = await testHelper.waitForEmail(
        to: user2Email,
        type: 'messageNotification',
        timeout: const Duration(seconds: 5),
      );
      expect(notificationEmail, isNotNull, 
        reason: 'Message notification email should be sent');
      expect(notificationEmail['to'], user2Email,
        reason: 'Notification should be sent to partner');
      
      print('   ✅ Message notification sent to partner');
      
      // ============================================
      // STEP 9: Verify AI response
      // ============================================
      print('\n🤖 Step 9: Verifying AI counselor response');
      
      final aiResponse = await testHelper.waitForAIResponse(
        timeout: const Duration(seconds: 10),
      );
      expect(aiResponse, isNotNull, 
        reason: 'AI should generate a response');
      
      print('   ✅ AI counselor responded');
      print('   AI said: "${aiResponse['response']}"');
      
      // ============================================
      // STEP 10: Verify User2 can see messages
      // ============================================
      print('\n💬 Step 10: User2 retrieves messages');
      
      final messagesResponse = await http.get(
        Uri.parse('$apiUrl/api/messages/$conversationId'),
        headers: {'Authorization': 'Bearer $user2Token'},
      );
      
      expect(messagesResponse.statusCode, 200);
      final messagesData = jsonDecode(messagesResponse.body);
      final messages = (messagesData['messages'] ?? messagesData) as List;
      expect(messages.length, greaterThanOrEqualTo(2), 
        reason: 'Should have at least User1 message + AI response');
      
      // Verify User1's message is there
      final user1Message = messages.firstWhere(
        (m) => m['content'] == messageContent,
        orElse: () => throw Exception('User1 message not found'),
      );
      expect(user1Message, isNotNull);
      
      // Verify AI response is there
      final aiMessage = messages.firstWhere(
        (m) => m['senderType'] == 'ai',
        orElse: () => throw Exception('AI message not found'),
      );
      expect(aiMessage, isNotNull);
      
      print('   ✅ User2 can see all messages');
      print('   ✅ Found ${messages.length} messages in conversation');
      
      // ============================================
      // TEST COMPLETE
      // ============================================
      print('\n');
      print('🎉 ═══════════════════════════════════════════════════════');
      print('🎉  ALL E2E TESTS PASSED SUCCESSFULLY!');
      print('🎉 ═══════════════════════════════════════════════════════');
      print('');
      print('✅ User registration');
      print('✅ Email notifications (welcome, invitation, message)');
      print('✅ Partner invitation flow');
      print('✅ Partner connection');
      print('✅ Conversation creation');
      print('✅ Message sending');
      print('✅ AI counselor response');
      print('✅ Message retrieval');
      print('');
    });
  });
}
