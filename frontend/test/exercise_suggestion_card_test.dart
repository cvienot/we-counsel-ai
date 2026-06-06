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

  testWidgets('completed AI exercise markers are not actionable', (
    tester,
  ) async {
    String? startedExerciseId;

    final message = Message(
      messageId: 'message-1',
      conversationId: 'conversation-1',
      senderId: 'ai-coach',
      senderName: 'Coach Sarah (AI Relationship Coach)',
      senderType: MessageSenderType.ai,
      content:
          '@Alice, here is the exercise you completed.\n\n'
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
            completedExerciseIds: const {'active-listening'},
            onExerciseSuggestion: (exerciseId) {
              startedExerciseId = exerciseId;
            },
          ),
        ),
      ),
    );

    expect(find.textContaining('[EXERCISE:'), findsNothing);
    expect(find.text('Active Listening Practice'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Tap to start the guided exercise'), findsNothing);

    await tester.tap(find.text('Completed'));
    expect(startedExerciseId, isNull);
  });

  testWidgets('AI commitment markers render as action plan cards', (
    tester,
  ) async {
    final message = Message(
      messageId: 'message-1',
      conversationId: 'conversation-1',
      senderId: 'ai-coach',
      senderName: 'Coach Sarah (AI Relationship Coach)',
      senderType: MessageSenderType.ai,
      content:
          'This sounds ready to practice.\n\n'
          '[COMMITMENT:pause-reflect-script]\n'
          'title=Practice the pause-reflect script\n'
          'agreement=Pause before explaining, reflect the feeling, then discuss facts.\n'
          'practice=Try the script once this week on a low-stakes topic.\n'
          'due_days=7',
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
          ),
        ),
      ),
    );

    expect(find.textContaining('[COMMITMENT:'), findsNothing);
    expect(find.text('This sounds ready to practice.'), findsOneWidget);
    expect(find.text('Action plan'), findsOneWidget);
    expect(find.text('Practice the pause-reflect script'), findsOneWidget);
    expect(
      find.textContaining('Pause before explaining', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('Try the script once this week', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Save commitment'), findsOneWidget);
  });
}
