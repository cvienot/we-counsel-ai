import 'package:flutter/material.dart';
import '../models/message.dart';
import '../l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isCurrentUser;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
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
          if (!alignRight) ...[
            _buildAvatar(context),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: alignRight
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!alignRight)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      _getLocalizedSenderName(context),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isAI
                            ? theme.colorScheme.secondary
                            : theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
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
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.content,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _getTextColor(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('HH:mm').format(
                          DateTime.fromMillisecondsSinceEpoch(message.timestamp),
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _getTextColor(context).withOpacity(0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (alignRight) ...[
            const SizedBox(width: 8),
            _buildAvatar(context),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final isAI = message.senderType == MessageSenderType.ai;
    final theme = Theme.of(context);

    return CircleAvatar(
      radius: 16,
      backgroundColor: isAI
          ? theme.colorScheme.secondary
          : theme.colorScheme.primary,
      child: isAI
          ? const Icon(
              Icons.psychology,
              size: 16,
              color: Colors.white,
            )
          : Text(
              message.senderName.isNotEmpty
                  ? message.senderName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
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
      return theme.colorScheme.secondary.withOpacity(0.1);
    } else if (alignRight) {
      return theme.colorScheme.primary;
    } else {
      return theme.colorScheme.outline.withOpacity(0.1);
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
}
