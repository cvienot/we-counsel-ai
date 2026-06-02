import 'package:flutter/material.dart';
import '../models/message.dart';
import '../l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'exercise_suggestion_card.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isCurrentUser;
  final Function(String exerciseId)? onExerciseSuggestion;
  final String? currentUserName;
  final String? partnerName;
  final Set<String> completedExerciseIds;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.onExerciseSuggestion,
    this.currentUserName,
    this.partnerName,
    this.completedExerciseIds = const <String>{},
  });

  String _getLocalizedSenderName(BuildContext context) {
    // If it's an AI message and the senderName contains "AI Counsellor", use localized version
    if (message.senderType == MessageSenderType.ai &&
        message.senderName.contains('AI Counsellor')) {
      return AppLocalizations.of(context)!.drSarahAiCounsellor;
    }
    // Otherwise, use the original sender name
    return message.senderName;
  }

  @override
  Widget build(BuildContext context) {
    final isAI = message.senderType == MessageSenderType.ai;
    final alignRight = isCurrentUser && !isAI;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: 16,
        // Add horizontal margins to keep messages from edges
        left: alignRight ? 48.0 : 0,
        right: alignRight ? 0 : 48.0,
      ),
      child: Row(
        mainAxisAlignment: alignRight
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!alignRight) ...[_buildAvatar(context), const SizedBox(width: 8)],
          Flexible(
            child: Column(
              crossAxisAlignment: alignRight
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!alignRight)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getLocalizedSenderName(context),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isAI
                                ? theme.colorScheme.secondary
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                          ),
                        ),
                        if (isAI) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondary.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.aiCoach,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.70,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _getBubbleColor(context),
                    borderRadius: BorderRadius.circular(18).copyWith(
                      bottomLeft: !alignRight
                          ? const Radius.circular(4)
                          : const Radius.circular(18),
                      bottomRight: alignRight
                          ? const Radius.circular(4)
                          : const Radius.circular(18),
                    ),
                    // Add subtle border for AI messages
                    border: isAI
                        ? Border.all(
                            color: theme.colorScheme.secondary.withValues(
                              alpha: 0.2,
                            ),
                            width: 1,
                          )
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MarkdownBody(
                        data: _getCleanContent(),
                        selectable: true,
                        inlineSyntaxes: [MentionSyntax()],
                        builders: {
                          'mention': MentionBuilder(
                            currentUserName: currentUserName,
                            partnerName: partnerName,
                            baseTextColor: _getTextColor(context),
                          ),
                        },
                        styleSheet: MarkdownStyleSheet(
                          p: theme.textTheme.bodyMedium?.copyWith(
                            color: _getTextColor(context),
                            height: 1.5,
                          ),
                          strong: theme.textTheme.bodyMedium?.copyWith(
                            color: _getTextColor(context),
                            fontWeight: FontWeight.bold,
                            height: 1.5,
                          ),
                          em: theme.textTheme.bodyMedium?.copyWith(
                            color: _getTextColor(context),
                            fontStyle: FontStyle.italic,
                            height: 1.5,
                          ),
                          listBullet: theme.textTheme.bodyMedium?.copyWith(
                            color: _getTextColor(context),
                          ),
                        ),
                        shrinkWrap: true,
                      ),
                      if (_getExerciseSuggestion() != null) ...[
                        ExerciseSuggestionCard(
                          exerciseId: _getExerciseSuggestion()!.exerciseId,
                          exerciseName: _getExerciseSuggestion()!.exerciseName,
                          isCompleted: completedExerciseIds.contains(
                            _getExerciseSuggestion()!.exerciseId,
                          ),
                          onStart: () {
                            if (onExerciseSuggestion != null) {
                              onExerciseSuggestion!(
                                _getExerciseSuggestion()!.exerciseId,
                              );
                            }
                          },
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('HH:mm').format(
                          DateTime.fromMillisecondsSinceEpoch(
                            message.timestamp,
                          ),
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _getTextColor(context).withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (alignRight) ...[const SizedBox(width: 8), _buildAvatar(context)],
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final isAI = message.senderType == MessageSenderType.ai;
    final theme = Theme.of(context);

    return CircleAvatar(
      radius: 18, // Slightly larger for better visibility
      backgroundColor: isAI
          ? theme.colorScheme.secondary
          : theme.colorScheme.primary,
      child: isAI
          ? const Text(
              '💙', // Heart emoji for AI counselor
              style: TextStyle(fontSize: 18),
            )
          : Text(
              message.senderName.isNotEmpty
                  ? message.senderName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  Color _getBubbleColor(BuildContext context) {
    final theme = Theme.of(context);
    final isAI = message.senderType == MessageSenderType.ai;
    final alignRight = isCurrentUser && !isAI;

    if (isAI) {
      // Softer, more inviting color for AI messages
      return theme.colorScheme.secondary.withValues(alpha: 0.08);
    } else if (alignRight) {
      return theme.colorScheme.primary;
    } else {
      return theme.colorScheme.outline.withValues(alpha: 0.1);
    }
  }

  Color _getTextColor(BuildContext context) {
    final theme = Theme.of(context);
    final isAI = message.senderType == MessageSenderType.ai;
    final alignRight = isCurrentUser && !isAI;

    if (alignRight) {
      return theme.colorScheme.onPrimary;
    } else {
      return theme.colorScheme.onSurface;
    }
  }

  /// Get exercise suggestion if present in message
  ExerciseSuggestion? _getExerciseSuggestion() {
    final isAI = message.senderType == MessageSenderType.ai;
    if (!isAI) return null;

    return ExerciseSuggestionCard.parseFromMessage(message.content);
  }

  /// Get message content with exercise marker removed
  String _getCleanContent() {
    final suggestion = _getExerciseSuggestion();
    if (suggestion != null) {
      return suggestion.cleanContent;
    }
    return message.content;
  }
}

// ---------------------------------------------------------------------------
// Custom Markdown inline syntax for @mentions
// ---------------------------------------------------------------------------

/// Parses `@Name` tokens into a custom `mention` element.
class MentionSyntax extends md.InlineSyntax {
  // Match @Word (including Unicode letters, digits, hyphens, underscores)
  MentionSyntax() : super(r'@([\w\u00C0-\u024F-]+)');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final name = match[1]!;
    final el = md.Element.text('mention', '@$name');
    el.attributes['name'] = name;
    parser.addNode(el);
    return true;
  }
}

/// Renders `mention` elements as inline highlighted chips with different colors
/// for the current user vs. partner, similar to Slack.
class MentionBuilder extends MarkdownElementBuilder {
  final String? currentUserName;
  final String? partnerName;
  final Color baseTextColor;

  // Slack-inspired colors
  static const _currentUserColor = Color(0xFF1264A3); // Blue
  static const _partnerColor = Color(0xFF9C27B0); // Purple

  MentionBuilder({
    this.currentUserName,
    this.partnerName,
    this.baseTextColor = Colors.black,
  });

  @override
  void visitElementBefore(md.Element element) {
    // Prevent default text handling — we handle it in visitElementAfterWithContext
  }

  @override
  Widget visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final name = element.attributes['name'] ?? '';
    final fullText = element.textContent;

    final isCurrentUser =
        currentUserName != null &&
        name.toLowerCase() == currentUserName!.toLowerCase();
    final isPartner =
        partnerName != null && name.toLowerCase() == partnerName!.toLowerCase();

    final Color chipColor;
    final Color textColor;
    if (isCurrentUser) {
      chipColor = _currentUserColor;
      textColor = _currentUserColor;
    } else if (isPartner) {
      chipColor = _partnerColor;
      textColor = _partnerColor;
    } else {
      chipColor = Colors.grey;
      textColor = Colors.grey.shade700;
    }

    // Use RichText with WidgetSpan to keep the mention inline
    return RichText(
      text: WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: chipColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            fullText,
            style: (preferredStyle ?? const TextStyle()).copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
