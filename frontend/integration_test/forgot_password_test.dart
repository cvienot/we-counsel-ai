import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:we_counsel/main.dart' as app;
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'e2e_test_helper.dart';

/// Helper: pump frames until [finder] finds at least one widget, or timeout.
Future<bool> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
  Duration pumpInterval = const Duration(milliseconds: 200),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(pumpInterval);
    if (finder.evaluate().isNotEmpty) return true;
  }
  return false;
}

/// Helper: settle the UI with a hard timeout.
Future<void> settleWithTimeout(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 5),
  Duration pumpInterval = const Duration(milliseconds: 100),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(pumpInterval);
  }
}

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

  group('Forgot Password E2E Test', () {
    testWidgets('User requests password reset and resets password',
        (WidgetTester tester) async {
      // ============================================
      // SETUP: Register a user via API
      // ============================================
      final testEmail = 'forgot-${DateTime.now().millisecondsSinceEpoch}@test.com';
      final originalPassword = 'OldPass123!';
      final newPassword = 'NewPass456!';

      print('🧪 Forgot Password E2E test');
      print('   Email: $testEmail');

      // Register user via API
      final registerRes = await http.post(
        Uri.parse('$apiUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': testEmail,
          'password': originalPassword,
          'firstName': 'Forgot',
          'lastName': 'Tester',
          'termsAccepted': true,
        }),
      );
      expect(registerRes.statusCode, 201,
          reason: 'User registration should succeed');
      print('   ✅ Test user registered via API');

      // Reset mock emails so we only see the password reset email
      await testHelper.resetMocks();

      // ============================================
      // STEP 1: Navigate to Forgot Password screen
      // ============================================
      print('\n📝 Step 1: Navigate to Forgot Password screen');

      app.main();
      await settleWithTimeout(tester, timeout: const Duration(seconds: 3));

      // Wait for login screen
      final foundLogin = await pumpUntilFound(
        tester,
        find.text('Forgot password?'),
        timeout: const Duration(seconds: 10),
      );
      expect(foundLogin, isTrue, reason: 'Login screen with forgot password link should appear');

      // Tap "Forgot password?" link
      await tester.tap(find.text('Forgot password?'));
      await settleWithTimeout(tester, timeout: const Duration(seconds: 2));

      // Verify forgot password screen appeared
      final foundForgotScreen = await pumpUntilFound(
        tester,
        find.text('Reset Password'),
        timeout: const Duration(seconds: 5),
      );
      expect(foundForgotScreen, isTrue,
          reason: 'Forgot password screen should appear');
      print('   ✅ Forgot password screen displayed');

      // ============================================
      // STEP 2: Submit email for password reset
      // ============================================
      print('\n📝 Step 2: Submit email for password reset');

      // Enter email
      final emailField = find.byType(TextFormField);
      expect(emailField, findsOneWidget);
      await tester.enterText(emailField, testEmail);
      await settleWithTimeout(tester, timeout: const Duration(seconds: 1));

      // Tap send reset link button
      final sendButton = find.text('Send Reset Link');
      expect(sendButton, findsOneWidget);
      await tester.tap(sendButton);
      await settleWithTimeout(tester, timeout: const Duration(seconds: 3));

      // Verify confirmation screen
      final foundConfirmation = await pumpUntilFound(
        tester,
        find.text('Check your email'),
        timeout: const Duration(seconds: 10),
      );
      expect(foundConfirmation, isTrue,
          reason: 'Should show email sent confirmation');
      print('   ✅ Confirmation screen displayed');

      // ============================================
      // STEP 3: Verify mock email was sent
      // ============================================
      print('\n📝 Step 3: Verify password reset email');

      final resetEmail = await testHelper.waitForEmail(
        to: testEmail,
        type: 'passwordReset',
        timeout: const Duration(seconds: 5),
      );
      expect(resetEmail, isNotNull, reason: 'Password reset email should be sent');
      expect(resetEmail['to'], testEmail);
      expect(resetEmail['resetToken'], isNotNull);
      final resetToken = resetEmail['resetToken'] as String;
      print('   ✅ Password reset email sent with token: ${resetToken.substring(0, 8)}...');

      // ============================================
      // STEP 4: Reset password via API (simulating clicking the email link)
      // ============================================
      print('\n📝 Step 4: Reset password via API');

      final resetRes = await http.post(
        Uri.parse('$apiUrl/api/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': resetToken,
          'newPassword': newPassword,
        }),
      );
      expect(resetRes.statusCode, 200,
          reason: 'Password reset should succeed');
      final resetBody = jsonDecode(resetRes.body);
      expect(resetBody['success'], isTrue);
      print('   ✅ Password reset successful');

      // ============================================
      // STEP 5: Verify new password works
      // ============================================
      print('\n📝 Step 5: Verify login with new password');

      final loginRes = await http.post(
        Uri.parse('$apiUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': testEmail,
          'password': newPassword,
        }),
      );
      expect(loginRes.statusCode, 200,
          reason: 'Login with new password should succeed');
      print('   ✅ Login with new password works');

      // Verify old password no longer works
      final oldLoginRes = await http.post(
        Uri.parse('$apiUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': testEmail,
          'password': originalPassword,
        }),
      );
      expect(oldLoginRes.statusCode, 401,
          reason: 'Old password should no longer work');
      print('   ✅ Old password rejected');

      // ============================================
      // STEP 6: Navigate back to login from forgot password
      // ============================================
      print('\n📝 Step 6: Test "Back to Login" navigation');

      // We should still be on the confirmation screen with "Back to Login"
      final backToLogin = find.text('Back to Login');
      if (backToLogin.evaluate().isNotEmpty) {
        await tester.tap(backToLogin);
        await settleWithTimeout(tester, timeout: const Duration(seconds: 2));

        final backOnLogin = await pumpUntilFound(
          tester,
          find.text('Sign In'),
          timeout: const Duration(seconds: 5),
        );
        expect(backOnLogin, isTrue,
            reason: 'Should navigate back to login screen');
        print('   ✅ Back to Login navigation works');
      }

      // ============================================
      // STEP 7: Test invalid/expired token
      // ============================================
      print('\n📝 Step 7: Test invalid token rejection');

      final invalidRes = await http.post(
        Uri.parse('$apiUrl/api/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': 'invalid-token-12345',
          'newPassword': 'SomePass123!',
        }),
      );
      expect(invalidRes.statusCode, 400,
          reason: 'Invalid token should be rejected');
      print('   ✅ Invalid token correctly rejected');

      // ============================================
      // STEP 8: Test reuse of already-used token
      // ============================================
      print('\n📝 Step 8: Test token reuse prevention');

      final reuseRes = await http.post(
        Uri.parse('$apiUrl/api/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': resetToken,
          'newPassword': 'AnotherPass789!',
        }),
      );
      expect(reuseRes.statusCode, 400,
          reason: 'Used token should be rejected');
      print('   ✅ Token reuse correctly prevented');

      // ============================================
      // STEP 9: Test non-existent email (should still return success)
      // ============================================
      print('\n📝 Step 9: Test email enumeration prevention');

      final unknownRes = await http.post(
        Uri.parse('$apiUrl/api/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': 'nonexistent-${DateTime.now().millisecondsSinceEpoch}@test.com',
        }),
      );
      expect(unknownRes.statusCode, 200,
          reason: 'Should return 200 even for unknown emails');
      final unknownBody = jsonDecode(unknownRes.body);
      expect(unknownBody['success'], isTrue);
      print('   ✅ Email enumeration prevention works');

      print('\n🎉 Forgot Password E2E test PASSED!');
    });
  });
}
