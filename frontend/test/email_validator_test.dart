import 'package:flutter_test/flutter_test.dart';
import 'package:we_counsel/utils/email_validator.dart';

void main() {
  test('accepts common production and test email formats', () {
    expect(isValidEmail('camille.vienot@gmail.com'), isTrue);
    expect(isValidEmail('camille.vienot+entrelace-e2e@gmail.com'), isTrue);
    expect(isValidEmail('user_name-1@example.co.uk'), isTrue);
    expect(isValidEmail('user@example.technology'), isTrue);
  });

  test('rejects malformed email addresses', () {
    expect(isValidEmail(''), isFalse);
    expect(isValidEmail('not-an-email'), isFalse);
    expect(isValidEmail('user@'), isFalse);
    expect(isValidEmail('@example.com'), isFalse);
    expect(isValidEmail('user@example'), isFalse);
    expect(isValidEmail('user..name@example.com'), isFalse);
  });
}
