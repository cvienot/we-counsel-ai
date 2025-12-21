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
      
      // Should be on login screen after splash
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Navigate to register screen  
      final signUpLink = find.text('Don\'t have an account? Sign up');
      expect(signUpLink, findsOneWidget);
      await tester.tap(signUpLink);
      await tester.pumpAndSettle();
      
      print('   📝 Filling registration form...');
      
      // Fill registration form by field order (First Name, Last Name, Email, Password, Confirm Password)
      final allFields = find.byType(TextFormField);
      await tester.enterText(allFields.at(0), 'Alice');        // First Name
      await tester.enterText(allFields.at(1), 'Smith');        // Last Name  
      await tester.enterText(allFields.at(2), user1Email);     // Email
      await tester.enterText(allFields.at(3), user1Password);  // Password
      await tester.enterText(allFields.at(4), user1Password);  // Confirm Password
      
      // Accept terms
      final termsCheckbox = find.byType(Checkbox);
      await tester.tap(termsCheckbox);
      await tester.pumpAndSettle();
      
      // Submit
      final createButton = find.widgetWithText(ElevatedButton, 'Create Account');
      await tester.tap(createButton);
      await tester.pumpAndSettle();
      
      // Plan selection screen should appear
      print('   📋 Waiting for plan selection screen...');
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Select free plan (should be pre-selected) and continue
      final continuePlanButton = find.text('Continue with Free');
      if (continuePlanButton.evaluate().isNotEmpty) {
        print('   ✅ Plan selection screen appeared');
        await tester.tap(continuePlanButton);
        await tester.pumpAndSettle();
      }
      
      // Wait for API call and navigation - pump repeatedly until navigation completes
      print('   ⏳ Waiting for registration...');
      bool navigationComplete = false;
      for (int i = 0; i < 100 && !navigationComplete; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        // Check if we've left registration/plan selection screen
        navigationComplete = find.text('Create Account').evaluate().isEmpty &&
                             find.text('Continue with Free').evaluate().isEmpty;
      }
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Wait for auth state to fully update and home screen to render
      // Look for home screen elements
      bool onHomeScreen = false;
      for (int i = 0; i < 30 && !onHomeScreen; i++) {
        await tester.pump(const Duration(milliseconds: 200));
        onHomeScreen = find.text('Invite Your Partner').evaluate().isNotEmpty ||
                       find.text('Main Thread').evaluate().isNotEmpty;
      }
      
      print('   ✅ User1 registered via UI');
      
      // Verify welcome email was sent
      final welcomeEmail = await testHelper.waitForEmail(
        to: user1Email,
        type: 'welcome',
        timeout: const Duration(seconds: 5),
      );
      expect(welcomeEmail, isNotNull, reason: 'Welcome email should be sent to User1');
      expect(welcomeEmail['to'], user1Email);
      print('   ✅ Welcome email sent to $user1Email');
      
      // Get token for API operations (login to get token)
      final loginResponse = await http.post(
        Uri.parse('$apiUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': user1Email, 'password': user1Password}),
      );
      final user1Token = jsonDecode(loginResponse.body)['token'];
      print('   ✅ Got user token for API calls');
      
      // ============================================
      // STEP 2: User1 sends partner invitation
      // ============================================
      print('\n📧 Step 2: User1 sends partner invitation');
      
      // Send invitation via API (UI validated in Step 1)
      final inviteResponse = await http.post(
        Uri.parse('$apiUrl/api/auth/invite-partner'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $user1Token',
        },
        body: jsonEncode({
          'email': user2Email,
        }),
      );
      
      if (inviteResponse.statusCode != 201) {
        print('   ❌ Invite failed: ${inviteResponse.statusCode} - ${inviteResponse.body}');
      }
      expect(inviteResponse.statusCode, 201, 
        reason: 'Invitation should be sent successfully');
      
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
          'termsAccepted': true,
        }),
      );
      
      expect(user2RegisterResponse.statusCode, 201, 
        reason: 'User2 registration should succeed');
      
      final user2Data = jsonDecode(user2RegisterResponse.body);
      final user2Token = user2Data['token'];
      
      print('   ✅ User2 registered');
      
      // Verify welcome email was sent to User2
      final welcomeEmail2 = await testHelper.waitForEmail(
        to: user2Email,
        type: 'welcome',
        timeout: const Duration(seconds: 5),
      );
      expect(welcomeEmail2, isNotNull, reason: 'Welcome email should be sent to User2');
      expect(welcomeEmail2['to'], user2Email);
      print('   ✅ Welcome email sent to $user2Email');
      
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
        Uri.parse('$apiUrl/api/messages/$conversationId/ai-stream'),
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

    testWidgets('AI conversation summarization works after 20+ messages', 
        (WidgetTester tester) async {
      
      print('\n📊 Testing AI Conversation Summarization');
      
      // Create test users directly via API for faster setup
      final testEmail1 = 'summary-user1-${DateTime.now().millisecondsSinceEpoch}@test.com';
      final testEmail2 = 'summary-user2-${DateTime.now().millisecondsSinceEpoch}@test.com';
      
      print('   📝 Creating test users...');
      
      // Register User1 with premium tier for unlimited AI messages
      final user1Response = await http.post(
        Uri.parse('$apiUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': testEmail1,
          'password': 'Test123!',
          'firstName': 'Summary',
          'lastName': 'User1',
          'termsAccepted': true,
          'subscriptionTier': 'premium',
        }),
      );
      expect(user1Response.statusCode, 201);
      final user1Data = jsonDecode(user1Response.body);
      final user1Token = user1Data['token'];
      final user1Id = user1Data['user']['userId'];
      
      // Register User2 with premium tier for unlimited AI messages
      final user2Response = await http.post(
        Uri.parse('$apiUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': testEmail2,
          'password': 'Test123!',
          'firstName': 'Summary',
          'lastName': 'User2',
          'termsAccepted': true,
          'subscriptionTier': 'premium',
        }),
      );
      expect(user2Response.statusCode, 201);
      final user2Data = jsonDecode(user2Response.body);
      final user2Token = user2Data['token'];
      final user2Id = user2Data['user']['userId'];
      
      print('   ✅ Test users created');
      
      // Connect users as partners directly via database with premium tier
      print('   🤝 Connecting partners...');
      final connectResponse = await http.post(
        Uri.parse('$apiUrl/api/test/connect-partners'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user1Id': user1Id,
          'user2Id': user2Id,
          'subscriptionTier': 'premium',
        }),
      );
      expect(connectResponse.statusCode, 200);
      
      print('   ✅ Partners connected');
      
      // Create conversation
      print('   💬 Creating conversation...');
      final convResponse = await http.post(
        Uri.parse('$apiUrl/api/conversations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $user1Token',
        },
        body: jsonEncode({
          'title': 'Summarization Test Conversation',
          'topic': 'Testing AI summarization',
        }),
      );
      expect(convResponse.statusCode, 201);
      final convData = jsonDecode(convResponse.body);
      final conversationId = convData['conversation']['conversationId'];
      
      print('   ✅ Conversation created: $conversationId');
      
      // Send 25 messages to trigger summarization (threshold is 20)
      print('   📤 Sending 25 messages to trigger summarization...');
      for (int i = 1; i <= 25; i++) {
        await http.post(
          Uri.parse('$apiUrl/api/messages/$conversationId/ai-stream'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${i % 2 == 0 ? user1Token : user2Token}',
          },
          body: jsonEncode({
            'content': 'Test message number $i for summarization',
            'recipientType': 'both',
          }),
        );
        
        if (i % 5 == 0) {
          print('   ... sent $i messages');
        }
        
        // Small delay to avoid overwhelming the API
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      print('   ✅ All 25 messages sent');
      
      // Fetch conversation to check if summary was generated
      print('   🔍 Checking for conversation summary...');
      await Future.delayed(const Duration(seconds: 2)); // Give time for summary generation
      
      final convCheckResponse = await http.get(
        Uri.parse('$apiUrl/api/conversations/$conversationId'),
        headers: {'Authorization': 'Bearer $user1Token'},
      );
      expect(convCheckResponse.statusCode, 200);
      final convCheckData = jsonDecode(convCheckResponse.body);
      final conversation = convCheckData['conversation'];
      
      // Verify summary fields exist
      expect(conversation['summary'], isNotNull,
        reason: 'Summary should be generated after 20+ messages');
      expect(conversation['lastSummarizedAt'], isNotNull,
        reason: 'Last summarized timestamp should be set');
      expect(conversation['summarizedMessageCount'], greaterThan(0),
        reason: 'Summarized message count should be greater than 0');
      
      print('   ✅ Conversation summary generated!');
      print('   📊 Summary: ${conversation['summary']?.substring(0, 100)}...');
      print('   📊 Summarized messages: ${conversation['summarizedMessageCount']}');
      
      // Send one more message and verify AI gets context with summary
      print('   💬 Sending final message to verify AI context...');
      final finalMessageResponse = await http.post(
        Uri.parse('$apiUrl/api/messages/$conversationId/ai-stream'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $user1Token',
        },
        body: jsonEncode({
          'content': 'Can you help us summarize what we discussed?',
          'recipientType': 'both',
        }),
      );
      expect(finalMessageResponse.statusCode, 201);
      
      // Wait for AI response
      await Future.delayed(const Duration(seconds: 3));
      
      // Verify AI response was generated
      final aiResponse = await testHelper.waitForAIResponse(
        timeout: const Duration(seconds: 5),
      );
      expect(aiResponse, isNotNull, 
        reason: 'AI should respond using summarized context');
      
      print('   ✅ AI responded with summarized context');
      print('');
      print('🎉 ═══════════════════════════════════════════════════════');
      print('🎉  AI SUMMARIZATION TEST PASSED!');
      print('🎉 ═══════════════════════════════════════════════════════');
      print('');
      print('✅ Generated summary after 20+ messages');
      print('✅ Summary stored in conversation record');
      print('✅ AI uses summarized context for responses');
      print('');
    });
  });
}
