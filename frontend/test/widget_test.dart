import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:we_counsel/main.dart';

void main() {
  testWidgets('App renders splash while auth initializes', (
    WidgetTester tester,
  ) async {
    WeCounselApp.resetRouter();

    await tester.pumpWidget(const ProviderScope(child: WeCounselApp()));
    await tester.pump();

    expect(find.text('We Connect'), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
