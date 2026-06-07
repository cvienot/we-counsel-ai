import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:we_counsel/l10n/app_localizations.dart';
import 'package:we_counsel/screens/auth/login_screen.dart';

void main() {
  testWidgets('login screen shows AI for couples motivation section', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LoginScreen(),
        ),
      ),
    );

    expect(find.text('Why AI for couples?'), findsOneWidget);
    expect(find.text('Designed around the couple'), findsOneWidget);
    expect(find.text('Technology that brings you back'), findsOneWidget);
    expect(find.textContaining('does not replace therapy'), findsOneWidget);
  });
}
