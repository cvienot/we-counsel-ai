import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:we_counsel/l10n/app_localizations.dart';
import 'package:we_counsel/models/message.dart';
import 'package:we_counsel/widgets/message_bubble.dart';

void main() {
  testWidgets('AI exercise markers render as actionable cards', (tester) async {
    String? startedExerciseId;

    final message = Message(
      messageId: 'message-1',
      conversationId: 'conversation-1',
      senderId: 'ai-coach',
      senderName: 'Coach Sarah (AI Relationship Coach)',
      senderType: MessageSenderType.ai,
      content:
          '@Alice, this sounds like a useful moment to slow down.\n\n'
          '[EXERCISE:active-listening] This will help you each reflect back what you heard.',
      recipientType: MessageRecipientType.both,
      timestamp: DateTime(2026, 5, 28, 12).millisecondsSinceEpoch,
      createdAt: DateTime(2026, 5, 28, 12),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MessageBubble(
            message: message,
            isCurrentUser: false,
            currentUserName: 'Alice',
            partnerName: 'Jordan',
            onExerciseSuggestion: (exerciseId) {
              startedExerciseId = exerciseId;
            },
          ),
        ),
      ),
    );

    expect(find.textContaining('[EXERCISE:'), findsNothing);
    expect(find.text('Active Listening Practice'), findsOneWidget);
    expect(find.text('Tap to start the guided exercise'), findsOneWidget);

    await tester.tap(find.text('Tap to start the guided exercise'));
    expect(startedExerciseId, 'active-listening');
  });
}
